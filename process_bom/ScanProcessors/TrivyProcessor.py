from process_bom.ScanProcessors.BaseProcessors import BaseProcessor
import subprocess
import json
from io import StringIO
import csv

from process_bom.ca_config import *

class TrivyProcessor(BaseProcessor):
    def __init__(self) -> None:
        super().__init__()
        self.tool_name = "Trivy"


    def _run_command_for_image(self, image_name_with_tag: str, result_type: str):
        if result_type == "cve":
            output_format = 'json'
        elif result_type == "sbom":
            output_format = 'cyclonedx'
        else:
            return { "fail_status": f"Invalid results type '{result_type}'" }

        with subprocess.Popen(
            ["trivy", "-q", "i", "--timeout", "10m", "-f", output_format, image_name_with_tag],
            stdout=subprocess.PIPE
        ) as proc:
            if proc.stderr == None and proc.stdout != None:
                output = proc.communicate()[0].decode("utf-8")
                if output != "" :
                    return json.loads(output)
        return { "fail_status": f"Failed to get the details using trivy for {image_name_with_tag}" }


    def parse_json(self, data: dict):
        '''
        This method will parse the JSON data to generate CVE details in desired structure.
        
        Parameters:
        - data (dict): JSON data provided
        
        Returns:
        - dict: Status of parsing and actual SBOM data
        '''
        vulnerabilities = {
            'UNKNOWN': [],
            'LOW' : [],
            'MEDIUM' : [],
            'HIGH' : [],
            'CRITICAL' : []
        }
        
        if 'fail_status' in data:
            return {'Status': False, 'Data': vulnerabilities}

        if bool(data.get("Results")):                           # Check if key exists and is not None
            for result in data["Results"]:
                if "Vulnerabilities" in result:
                    for vul in result["Vulnerabilities"]:
                        required_data = {
                            "VulnerabilityID": vul["VulnerabilityID"],
                            "PkgName": vul["PkgName"],
                            "InstalledVersion": vul["InstalledVersion"] if "InstalledVersion" in vul else "",
                            "FixedVersion": vul["FixedVersion"] if "FixedVersion" in vul else "",
                            "SeveritySource": vul["SeveritySource"] if "SeveritySource" in vul else "",
                            "URL": vul["PrimaryURL"] if "PrimaryURL" in vul else ""
                        }
                        vulnerabilities[vul["Severity"]].append(required_data)

        return { "Status": True, "Data": vulnerabilities }


    def parse_cyclonedx(self, data: dict):
        '''
        This method will parse the CycloneDX data to generate SBOM in desired structure.
        
        Parameters:
        - data (dict): CycloneDX data provided.
        
        Returns: 
        - dict: Status of parsing and actual SBOM data.
        '''
        sbom = []
        ret_status = "components" in data
        if bool(data.get("components")):                       # Check if key exists and is not None
            for component in data["components"]:
                try:
                    licenses = ', '.join(
                        map(
                            lambda l: l["license"]["name"] if "name" in l["license"] else l["license"]["id"],
                            component["licenses"]
                        )
                    )
                except KeyError:
                    licenses = "-"
                try:
                    sbom.append({
                        "name": component["name"],
                        "version": component["version"],
                        "licenses": licenses
                    })
                except KeyError:
                    # Skip invalid components that don't have 'name' or 'version'
                    pass

        return { "Status": ret_status, "Data": sbom }


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
        image_name_with_tag=f"{image_name}:{tag}"
        cve_data = self._run_command_for_image(image_name_with_tag=image_name_with_tag, result_type='cve')

        return self.parse_json(cve_data)


    def generate_sbom_details(self, repo, image_name, tag):
        '''
        This method will generate SBOM by executing the necessary commands.
               
        Parameters:
        - repo (str): Repository of Image
        - image_name (str): name of image for which CVE details are to be generated
        - tag (str):tag of image for which CVE details are to be generated.
        
        Returs:
        - dict: Generat and parsed SBOM
        '''
        super().generate_sbom_details(repo, image_name, tag)
        image_name_with_tag=f"{image_name}:{tag}"
        sbom_data = self._run_command_for_image(image_name_with_tag, result_type='sbom')
        
        return self.parse_cyclonedx(sbom_data)
    
    def get_bom_details_from_cos(self, package_name: str, version: str, scan_type: str):
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
            print(f"ⓘ No CVE data available for {scan_type}-scan using {self.tool_name} ⓘ")
        else:
            cves = self.parse_json(cve_details)

        sbom_details = self.get_sbom_json(
            package_name=package_name,
            version=version,
            repo="local",
            scan_type=scan_type,
            file_format="cyclonedx"
        )
        if not sbom_details:
            print(f"ⓘ No SBOM data available for {scan_type}-scan using {self.tool_name} ⓘ")
        else:
            sbom = self.parse_cyclonedx(sbom_details)

        return cves, sbom



