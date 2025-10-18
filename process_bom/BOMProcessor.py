

# Import Scanning Processors for initialization
from process_bom.ScanProcessors.TrivyProcessor import TrivyProcessor
from process_bom.ScanProcessors.SyftProcessor import SyftProcessor
from process_bom.ScanProcessors.GrypeProcessor import GrypeProcessor
from process_bom.ScanProcessors.ClairProcessor import ClairProcessor
from process_bom.ca_config import *

import tarfile
import csv
import json
from io import BytesIO, StringIO
from datetime import datetime, timezone

class BOMProcessor:

    def __init__(self) -> None:
        self.bom_tools = {
            tool: {
                "obj": eval(f"{tool}Processor()"),
                "status": False
            }
            for tool in BOM_TOOLS
        }

    def generate_combined_cves(self , temp_combined_cves):
        """
        Generate final combined CVEs of the form { "name": <name>, "InstalledVersion": <InstalledVersion>, ...<tools>: ...<tools that found CVE> }

        Args:
        temp_combined_cves (dict)

        Returns:
            List: combined_cves
        """
        combined_cves = []
        for k, v in temp_combined_cves.items():
            dependency_name, vulnerability_id = k
            combined_cves.append({
                "PkgName": dependency_name,
                "VulnerabilityID": vulnerability_id,
                **v
            })
        return combined_cves

    def generate_combined_sboms(self , temp_combined_sbom):
        """
        Generate final combined SBOM of the form { "name": <name>, "version": <version>, ...<tools>: ...<licenses> }

        Args:
        temp_combined_sbom (dict)

        Returns:
            List: combined_sbom
        """
        combined_sbom = []
        for k, v in temp_combined_sbom.items():
            dependency_name, dependency_version = k
            combined_sbom.append({
                "name": dependency_name,
                "version": dependency_version,
                **v
            })
        return combined_sbom

    def get_bom_details_from_cos(self, package_name: str, version: str):
        """
        Retrieve Bill of Materials (BOM) details from Cloud Object Storage (COS) for a specific package and version.

        Args:
            package_name (str): The name of the package for which BOM details are to be retrieved.
            version (str): The version of the package for which BOM details are to be retrieved.

        Returns:
            dict: A dictionary containing the BOM details, including the tag, link, tools, source, and image information.
        """
        bom_details = {
            "Tag": version,
            "Link": "#",
            "Tools": {},
            "source": {},
            "image": {}
        }

        for scan_type in SCAN_TYPES:
            bom_details["Tools"][scan_type] = {}
            combined_cves = self._get_combined_cves(scan_type, package_name, version, bom_details)
            combined_sbom = self._get_combined_sbom(scan_type, package_name, version, bom_details)

            bom_details[scan_type]["SBOM"] = combined_sbom
            bom_details[scan_type]["CVE"] = combined_cves

        return bom_details


    def _get_combined_cves(self, scan_type, package_name, version, bom_details):
        """
        Get combined CVEs for a given package and version.

        Parameters:
        - scan_type (str): Type of scan (e.g., "Vulnerability", "License").
        - package_name (str): Name of the package.
        - version (str): Version of the package.
        - bom_details (dict): Dictionary containing BOM details.

        Returns:
        - dict: Combined CVEs for the package and version.
        """
        temp_combined_cves = {}

        for tool, tool_details in self.bom_tools.items():
            cves, _ = tool_details["obj"].get_bom_details_from_cos(package_name, version, scan_type)
            bom_details["Tools"][scan_type][tool] = {"CVE": False, "SBOM": False}

            if not cves or not cves.get("Status"):
                continue

            bom_details["Tools"][scan_type][tool]["CVE"] = True
            self._merge_cves(tool, cves["Data"], temp_combined_cves)

        return self._format_combined_cves(temp_combined_cves)


    def _merge_cves(self, tool, cve_data, temp_combined_cves):
        """
        Merge CVE data into a temporary dictionary.

        Args:
        tool (str): The name of the tool used to fetch CVE data.
        cve_data (dict): A dictionary containing CVE data for different severities.
        temp_combined_cves (dict): A temporary dictionary to store merged CVE data.

        Returns:
        dict: The updated temporary dictionary with merged CVE data.
        """
        for severity in ["CRITICAL", "HIGH", "MEDIUM", "LOW"]:
            for data in cve_data.get(severity, []):
                key = (data["PkgName"], data["VulnerabilityID"])
                if key not in temp_combined_cves:
                    temp_combined_cves[key] = {
                        "InstalledVersion": data["InstalledVersion"],
                        "FixedVersion": data["FixedVersion"],
                        "Severity": severity
                    }
                temp_combined_cves[key][tool] = data["URL"]


    def _format_combined_cves(self, temp_combined_cves):
        """
        Format combined CVEs into a list of dictionaries.

        Args:
            temp_combined_cves (dict): A dictionary of tuples and dictionaries.
                The keys are tuples of package name and vulnerability ID, and the
                values are dictionaries containing details about the vulnerability.

        Returns:
            list: A list of dictionaries, where each dictionary represents a
                vulnerability and contains the package name, vulnerability ID, and
                any additional details.
        """
        return [
            {
                "PkgName": pkg,
                "VulnerabilityID": vuln_id,
                **details
            }
            for (pkg, vuln_id), details in temp_combined_cves.items()
        ]


    def _get_combined_sbom(self, scan_type, package_name, version, bom_details):
        """
        Get combined SBOM for a given package and version.

        Args:
            scan_type (str): Type of scan (e.g., "Vulnerability", "License").
            package_name (str): Name of the package.
            version (str): Version of the package.
            bom_details (dict): Dictionary containing BOM details.

        Returns:
            dict: Combined SBOM for the package and version.
        """
        temp_combined_sbom = {}

        for tool, tool_details in self.bom_tools.items():
            _, sbom = tool_details["obj"].get_bom_details_from_cos(package_name, version, scan_type)
            bom_details["Tools"][scan_type].setdefault(tool, {"CVE": False, "SBOM": False})

            if not sbom or not sbom.get("Status"):
                continue

            bom_details["Tools"][scan_type][tool]["SBOM"] = True
            self._merge_sbom(tool, sbom["Data"], temp_combined_sbom)

        return self._format_combined_sbom(temp_combined_sbom)


    def _merge_sbom(self, tool, sbom_data, temp_combined_sbom):
        """
        Merge SBOM data for a specific tool into a temporary combined SBOM.

        Args:
        tool (str): The name of the tool.
        sbom_data (list): A list of dictionaries containing SBOM data for the tool.
        temp_combined_sbom (dict): A dictionary to store the merged SBOM data.

        Returns:
        None
        """
        for data in sbom_data:
            key = (data["name"], data["version"])
            if key not in temp_combined_sbom:
                temp_combined_sbom[key] = {}
            temp_combined_sbom[key][tool] = data["licenses"]


    def _format_combined_sbom(self, temp_combined_sbom):
        """
        Format the combined SBOM into a list of dictionaries.

        Args:
            temp_combined_sbom (dict): A dictionary of tuples containing the name and version of each package, and additional details.

        Returns:
            list: A list of dictionaries, where each dictionary represents a package and contains its name, version, and any additional details.
        """
        return [
            {
                "name": name,
                "version": version,
                **details
            }
            for (name, version), details in temp_combined_sbom.items()
        ]



    def generate_combined_csv(self, data: list):
        """
        Generate a combined CSV from a list of dictionaries.

        Args:
            data (list): A list of dictionaries, where each dictionary represents a row in the CSV.

        Returns:
            str: The combined CSV as a string.
        """
        output = StringIO()
        # List out all possible tools from the data, to be used as column headers in CSV
        tools = set()
        for item in data:
            tools.update(tuple(item.keys()))
        writer = csv.DictWriter(output, tools)
        writer.writeheader()

        for row in data:
            writer.writerow(row)

        return output.getvalue()




