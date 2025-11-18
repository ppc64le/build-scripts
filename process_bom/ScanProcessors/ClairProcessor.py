from process_bom.ScanProcessors.BaseProcessors import BaseProcessor
import subprocess
import json
from io import StringIO
import csv

from process_bom.ca_config import *

class ClairProcessor(BaseProcessor):
    def __init__(self) -> None:
        super().__init__()
        self.tool_name = "Clair"


    def _run_command_for_image(self, image_name_with_tag: str, result_type: str):
        if result_type == "cve":
            output_format = "json"
        elif result_type == "sbom":
            output_format = "cyclonedx-json"
        else:
            return { "fail_status": f"Invalid results type '{result_type}'" }

        with subprocess.Popen(
            ["clairctl", "-c", CLAIR_CONFIG_FILE, "report", "--host", CLAIR_CONTAINER_HOST, "-o", output_format, image_name_with_tag],
            stdout=subprocess.PIPE
        ) as proc:
            if proc.stderr == None and proc.stdout != None:
                output = proc.communicate()[0].decode("utf-8")
                if output != "" :
                    return json.loads(output)
        return {
            "fail_status": f"Failed to get the details using Clair for {image_name_with_tag}"
        }


    def parse_json(self, data: dict) -> dict:
        '''
        This method will parse the JSON data to generate CVE details in desired structure.
        
        Parameters:
        - data (dict): JSON data provided
        
        Returns:
        - dict: Status of parsing and actual SBOM data
        '''
        vulnerabilities = {
            'URL': "https://avd.aquasec.com/nvd/",
            'UNKNOWN': [],
            'LOW' : [],
            'MEDIUM' : [],
            'HIGH' : [],
            'CRITICAL' : [],
            'NEGLIGIBLE' : []
        }
        cve_mapping ={
            "Critical" : "CRITICAL",
            "Important" : "HIGH",
            "Moderate" : "MEDIUM",
            "Low" : "LOW"
        }

        if 'fail_status' in data:
            return { "Status": False, "Data": vulnerabilities }

            # Severity levels in Clair
            # https://access.redhat.com/security/updates/classification/
            # Critical -> CRITICAL
            # Important -> HIGH
            # Moderate -> MEDIUM
            # Low -> LOW

        if bool(data.get("vulnerabilities")):
            if len(data["vulnerabilities"]):
                for key, value in data["vulnerabilities"].items():
                    req ={
                        "PkgName": value["package"]["name"],
                        "InstalledVersion": value["package"]["version"],
                        "FixedVersion": value["fixed_in_version"],
                        "SeveritySource": value["repository"].get("name", "")
                    }
                    for cve_URL in value["links"].split(" "):
                        req['VulnerabilityID'] = cve_URL.split("/")[-1]
                        req["URL"] = cve_URL
                        vulnerabilities[cve_mapping[value["severity"]] if len(value["severity"]) else 'NEGLIGIBLE'].append(req)

        return { "Status": True, "Data": vulnerabilities }


    def parse_cyclonedx(self, data: dict) -> dict:
        return super().parse_cyclonedx(data)    

    def generate_cve_details(self, repo: str, image_name: str, tag: str):
        '''
        This method will generate CVE details by executing the necessary commands.
        
        Parameters:
        - repo (str): Repository of Image
        - image_name (str): name of image for which CVE details are to be generated
        - tag (str):tag of image for which CVE details are to be generated.
        
        Returs:
        - dict: Generat and parsed CVE
        '''
        super().generate_cve_details(repo, image_name, tag)
        image_name_with_tag =  f"{'docker:' if repo == 'docker' else ''}{image_name}:{tag}"
        cve_details = self._run_command_for_image(
            image_name_with_tag=image_name_with_tag,
            result_type="cve"
        )
        
        return self.parse_json(cve_details)


    def generate_sbom_details(self, repo: str, image_name: str, tag: str):
        return super().generate_sbom_details(repo, image_name, tag)    

    def get_bom_details_from_cos(self, package_name: str, version: str, scan_type: str) -> dict:
        '''
        This method gets the cve and sbom details of the relevant scanners from Cloud Object Storage.
        
        Parameters:
        - package_name (str): Package name for which SBOM and CVE details need to be fetched.
        - version (str): Version of the package the CVE and SBOM details need to be fetched.
        - scan_type (str): The scan type of the package (image / source)
        
        returns:
        - cves (json) and sbom (json): returns the CVE and SBOm details of the package.
        '''
        cves = sbom = None

        cve_details = self.get_cves_json(
            package_name=package_name,
            version=version,
            repo="local",
            scan_type=scan_type,
            file_format="json"
        )
        if not cve_details:
            
            print(f"Skipping Clair !!")
        else:
            cves = self.parse_json(cve_details)

        return cves, sbom





