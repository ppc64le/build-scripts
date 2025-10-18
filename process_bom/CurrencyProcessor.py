import json
import os
import datetime

from process_bom.ca_config import SBOM_CVE_DIR, SCAN_TYPES
from process_bom.BOMProcessor import BOMProcessor
from process_bom.COSWrapper import COSWrapper
from process_bom.LicensesProcessor import LicensesProcessor

CLOUD_OBJECT_CVE_SBOM_BUCKET = "cloud-object-cve-sbom-bucket"

class CurrencyProcessor:
    
    bom_processor = BOMProcessor()
    licenses_processor = LicensesProcessor()
    cos = COSWrapper(CLOUD_OBJECT_CVE_SBOM_BUCKET)
    jenkins_jobs_database = 'currency_jenkins_build_history'

    database_name = "package_build_details"
    currency_build_logs = "currency_build_logs"

    def update_local_build_details_in_database(self, package_name: str, version: str):
        """
        Updates the local build details in the database for a given package name and version.

        Args:
            package_name (str): The name of the package.
            version (str): The version of the package.
            response (dict): The response object containing the updated details.

        Returns:
            None
        """
        os.mkdir(SBOM_CVE_DIR)
        required_package_details = self._get_package_details(package_name, version)
        #required_package_details["wheel_status"] = response["wheel_status"]
        required_package_details["Created"] = str(datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None))

        result = []
        try:
                result.append(required_package_details)
                #result = self._update_or_append(result, required_package_details, file_path_to_json)
                self.get_image_details_for_package(result,package_name=package_name,version=version)
        except Exception as e:
            print("Exception occurred:", e)


    def _get_package_details(self, package_name: str, version: str):
        """
        Retrieve package details from Bill of Materials (BOM) and add creation timestamp.

        Args:
            package_name (str): Name of the package.
            version (str): Version of the package.

        Returns:
            dict: Package details including creation timestamp.
        """
        required_package_details = self.bom_processor.get_bom_details_from_cos(package_name, version)
        required_package_details["Created"] = str(datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None))
        return required_package_details


    def _update_or_append(self, result, required_package_details, file_path_to_json):
        """
        Update or append a required package details to the result list.

        Parameters:
        result (list): The list of required package details.
        required_package_details (dict): The details of the required package.
        file_path_to_json (str): The file path to the JSON file.

        Returns:
        None
        """
        for i, item in enumerate(result):
            if item["Tag"] == required_package_details["Tag"]:
                result[i] = required_package_details
                self._write_to_file(result, file_path_to_json)
                return
        result.append(required_package_details)
        return result

    def get_image_details_for_package(self, result,package_name: str,version: str ):
        """
        Retrieve image details for a given package name.

        Parameters:
        package_name (str): The name of the package for which image details are to be retrieved.

        Returns:
        dict: A dictionary containing the image details for the specified package.
        """

        try:
            new_results = self._normalize_json_response(result)    
            final_result = self._process_local_data(new_results, package_name=package_name)
            with open(f"{package_name}_{version}.json", 'w') as outfile:
                json.dump(final_result, outfile, indent=4)
            cos = COSWrapper(CLOUD_OBJECT_CVE_SBOM_BUCKET)
            artifact_name=f"{package_name}_{version}.json"
            response = cos.push_artifacts_sbomcve(artifact_name=artifact_name)
            if response:
                print(f"Successfully pushed {package_name}_{version}.json to Cloud Object Storage.")
        except FileExistsError as e:
            print("File does not exist:", e)
            return {}
    
    def _normalize_json_response(self, data):
        """
        Ensures JSON response is always a list of dicts.
        - If it's a dict ({}), wrap in a list.
        - If it's already a list ([{}]), return as-is.
        """
        if isinstance(data, dict):
            return [data]
        elif isinstance(data, list):
            return data
        else:
            raise ValueError("Unsupported JSON structure (must be dict or list)")

    def _process_local_data(self, results, package_name):
        """
        Process the local data when _id does not exist in the results.

        Args:
            results (list): List of results to process.
            package_name (str): Name of the package to process.

        Returns:
            dict: Dictionary containing the processed results.
        """
        for item in results:
            for scan in SCAN_TYPES:
                if scan in item:
                    source = item[scan]
                    source["SBOM"] = self.licenses_processor.evaluate_licenses(source["SBOM"])
                else:
                    print("Empty File")
                    return {}
        
        # Handle ICR, QUAY, and DOCKER fields
        return {
            "package": package_name,
            "icr": [],
            "quay": [],
            "local": results
        }

    def _get_empty_data(self, package_name):
        """
        Return empty data when no response is received.

        Args:
            package_name (str): Name of the package.

        Returns:
            dict: Empty data dictionary with keys "package", "icr", "quay", and "local".
        """
        return {
            "package": package_name,
            "icr": [],
            "quay": [],
            "local": []
        }
    
    def _remove_existing_file(self, filepath: str):
        """
        This function removes a file if it exists.

        Parameters:
        filepath (str): The path to the file to be removed.

        Returns:
        None
        """
        if os.path.exists(filepath):
            os.remove(filepath)
            


