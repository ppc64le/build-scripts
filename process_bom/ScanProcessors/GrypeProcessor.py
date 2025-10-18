from process_bom.ScanProcessors.BaseProcessors import BaseProcessor
import subprocess
import json
from io import StringIO
import csv

from process_bom.ca_config import *
class GrypeProcessor(BaseProcessor):
    def __init__(self) -> None:
        super().__init__()
        self.tool_name = "Grype"


    def _run_command_for_image(self, image_name_with_tag: str, result_type: str):
        if result_type == "cve":
            output_format = "json"
        elif result_type == "sbom":
            output_format = "cyclonedx-json"
        else:
            return { "fail_status": f"Invalid results type '{result_type}'" }

        with subprocess.Popen(
            ["grype", "-q", "-s", "AllLayers", "-o", output_format, image_name_with_tag],
            stdout=subprocess.PIPE
        ) as proc:
            if proc.stderr == None and proc.stdout != None:
                output = proc.communicate()[0].decode("utf-8")
                if output != "" :
                    return json.loads(output)
        return { "fail_status": f"Failed to get the details using Grype for {image_name_with_tag}" }


    def parse_json(self, data: dict) -> dict:
        '''
        This method will parse the JSON data to generate CVE details in desired structure.
        
        Parameters:
        - data (dict): JSON data provided
        
        Returns:
        - dict: Status of parsing and actual SBOM data
        '''
        vulnerabilities = {
            'UNKNOWN': [],
            'LOW': [],
            'MEDIUM': [],
            'HIGH': [],
            'CRITICAL': [],
            'NEGLIGIBLE': []
        }

        if "fail_status" in data:
            return { "Status": False, "Data": vulnerabilities }

        for i in data["matches"]:
            req = {
                "VulnerabilityID": i["vulnerability"]["id"],
                "PkgName": i["artifact"]["name"],
                "InstalledVersion": i["artifact"]["version"],
                "FixedVersion": ",".join(i["vulnerability"]["fix"]["versions"]),
                "SeveritySource": i["vulnerability"]["namespace"],
                "URL": i["vulnerability"]["dataSource"]
            }
            vulnerabilities[i["vulnerability"]["severity"].upper()].append(req)
        return { "Status": True, "Data": vulnerabilities }


    def parse_cyclonedx(self, data: dict) -> dict:
        '''
        This method will parse the CycloneDX data to generate SBOM in desired structure.
        
        Parameters:
        - data (dict): CycloneDX data provided.
        
        Returns: 
        - dict: Status of parsing and actual SBOM data.
        '''
        sbom = []
        status = False

        if 'components' in data:
            status = True
            for component in data['components']:
                if component['type'] == 'library' or component['type'] == 'application':
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
                        'name' : component['name'],
                        'version': component['version'] if 'version' in component else '-',
                        'licenses': licenses
                    })
                    except KeyError:
                        pass
        
        return { "Status": status, "Data": sbom }


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
        image_name_with_tag = f"{'docker:' if repo == 'docker' else ''}{image_name}:{tag}"
        cve_details = self._run_command_for_image(
            image_name_with_tag=image_name_with_tag,
            result_type="cve"
        )

        return self.parse_json(cve_details)


    def generate_sbom_details(self, repo: str, image_name: str, tag: str):
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
        image_name_with_tag = ('docker:' if repo == 'docker' else '')+f"{image_name}:{tag}"
        sbom_details = self._run_command_for_image(
            image_name_with_tag=image_name_with_tag,
            result_type="sbom"
        )

        return self.parse_cyclonedx(sbom_details)

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
            print(f"ⓘ No CVE data available for {scan_type}-scan using {self.tool_name} ⓘ")
        else:
            cves = self.parse_json(cve_details)

        sbom_details = self.get_sbom_json(
            package_name=package_name,
            version=version,
            repo="local",
            scan_type=scan_type,
            file_format="json"
        )
        if not sbom_details:
            print(f"ⓘ No SBOM data available for {scan_type}-scan using {self.tool_name} ⓘ")
        else:
            sbom = self.parse_cyclonedx(sbom_details)
        
        return cves, sbom




