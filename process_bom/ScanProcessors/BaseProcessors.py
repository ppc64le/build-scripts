from abc import ABC, abstractmethod
from process_bom.COSWrapper import COSWrapper

from process_bom.ca_config import *

# Abstract 'BaseProcessor' class to be inherited by all Scanning Processors
class BaseProcessor(ABC):
    def __init__(self) -> None:
        super().__init__()
        self.cos_wrapper = COSWrapper(CLOUD_OBJECT_BUCKET_NAME)
        self.tool_name = ""

    @abstractmethod
    def _run_command_for_image(self, image_name_with_tag: str, result_type: str):
        """
        This method executes actual <tool> command by creating a subprocess.

        :param image_name_with_tag: image name and its exact tag to be scanned.
        :type user_data: str
        :param result_type: can be either 'cve' or 'sbom' based on what output we want.
        :type result_type: str
        :return: Result of <tool> command
        :rtype: dict
        """
        raise NotImplementedError("This method needs to be defined mandatorily!")

    @abstractmethod
    def parse_json(self, data: dict) -> dict:
        """
        This method will parse the JSON data to generate CVE details in desired structure.

        :param data: JSON data provided.
        :type data: dict
        :return: Status of parsing and actual SBOM data.
        :rtype: dict
        """
        pass

    @abstractmethod
    def parse_cyclonedx(self, data: dict) -> dict:
        """
        This method will parse the CycloneDX data to generate SBOM in desired structure.

        :param data: CycloneDX data provided.
        :type data: dict
        :return: Status of parsing and actual SBOM data.
        :rtype: dict
        """
        pass

    #This function gets the CVE json data from the Cloud Object Storage. 
    def get_cves_json(self, package_name: str, version: str, repo: str, scan_type: str, file_format: str):
        """
        This method will get the CVE details from the Cloud Object Storage.
        
        Parameters
        - package_name (str): name of the package. 
        - version (str): version of the package.
        - repo (str): the repo is local or icr registry.
        - scan_type (str): scan type is if you want the json data for the image or source CVE.
        - file_format (str): the file format in which the data of the results is (.json / .cyclondx)
        
        Returns:
        - json: The CVE data of a particular package and a particular version.
        """
        return self.cos_wrapper.get_artifacts(
            package_name=package_name,
            version=version,
            result_type="vulnerabilities",
            tool=self.tool_name,
            repo=repo,
            file_format=file_format,
            scan_type=scan_type
        )

    # This function gets the sbom json data from the Cloud Object storage.
    def get_sbom_json(self, package_name: str, version: str, repo: str, scan_type: str, file_format: str):
        """
        This method will get the SBOM details from the Cloud Object Storage.
        
        Parameters
        - package_name (str): name of the package. 
        - version (str): version of the package.
        - repo (str): the repo is local or icr registry.
        - scan_type (str): scan type is if you want the json data for the image or source CVE.
        - file_format (str): the file format in which the data of the results is (.json / .cyclondx)
        
        Returns:
        - json: The SBOM data of a particular package and a particular version.
        """
        return self.cos_wrapper.get_artifacts(
            package_name=package_name,
            version=version,
            result_type="sbom",
            tool=self.tool_name,
            repo=repo,
            file_format=file_format,
            scan_type=scan_type
        )
    
    @abstractmethod
    def generate_cve_details(self, repo: str, image_name: str, tag: str):
        """
        This method will generate CVE details by executing the necessary commands.

        :param repo: Repository of Image.
        :type repo: dict
        :param image_name: name of image for which CVE details are to be generated.
        :type image_name: str
        :param tag: tag of image for which CVE details are to be generated.
        :type tag: str
        :return: Generated & parsed CVE details.
        :rtype: dict
        """
        print(f"{self.tool_name}Processor: generate_cve_details")

    @abstractmethod
    def generate_sbom_details(self, repo: str, image_name: str, tag: str):
        """
        This method will generate SBOM by executing the necessary commands.

        :param repo: Repository of Image.
        :type repo: dict
        :param image_name: name of image for which SBOM is to be generated.
        :type image_name: str
        :param tag: tag of image for which SBOM is to be generated.
        :type tag: str
        :return: Generated & parsed SBOM.
        :rtype: dict
        """
        print(f"{self.tool_name}Processor: generate_sbom_details")

    @abstractmethod
    def get_bom_details_from_cos(self, package_name: str, version: str, scan_type: str) -> dict:
        """
        This method will generate BOM by executing the necessary commands.

        :param package_name: Name of package for which BOM details are to be fetched.
        :type package_name: dict
        :param version: Version of package for which BOM details are to be fetched.
        :type version: dict
        :param scan_type: Type of Scan - 'source' for source code scanning, 'image' for docker image scanning
        :type scan_type: str
        :return: final BOM details to be returned in desired structure.
        :rtype: dict
        """
        pass
