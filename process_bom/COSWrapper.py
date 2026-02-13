import os
import tarfile
import requests
import json
import shutil
import zipfile
import re
import xml.etree.ElementTree as ET

from process_bom.ca_config import *

class COSWrapper:
    """
    This class is a wrapper for Cloud Object Storage operations.
    """
    module_bucket = None
    no_file = "No file at"
    def __init__(self, module_bucket):
        self.module_bucket = module_bucket

    def get_auth_token(self):
        """
        Generate Authorization token from IAM, in order to perform various Cloud Object Storage operations.
        :return: Authorization access token for Cloud Object Storage operations.
        :rtype: str
        """
        data = {
            "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
            "apikey": IAM_WRITER_API_KEY
        }
        response = requests.post(
            IAM_AUTH_URL,
            data = data,
            headers = {
                "Content-Type": "application/x-www-form-urlencoded",
                "accept": "application/json",
                "ibm-service-instance-id": SERVICE_INSTANCE_ID
            }
        ).json()
        return response.get("access_token")

    def download_artifacts(self, package_name: str, version: str):
        '''
        Download artifacts from the COS bucket as a zip file.
        :return: zipfile path to be downloaded/
        :rtype: string 
        '''
        print("Downloading artifacts for", package_name)
        file_names = []
        for scan_type in SCAN_TYPES:
            download_url =  f"{CLOUD_OBJECT_STORAGE_URL}/{CLOUD_OBJECT_BUCKET_NAME}/{package_name}/{version}/{scan_type}_scanner.tar.gz"
            response = requests.get(
                download_url,
                headers = {
                    "Authorization": f"Bearer {self.get_auth_token()}"
                }
            )
            
            if response.status_code == 200 :
                file_path = f"{package_name}_{version}_{scan_type}_scanner.tar.gz"
                with open(file_path, 'wb') as fh:
                    fh.write(response.content)
                file_names.append(file_path)
                
        zipfilename = f"{OUTPUT_DIR}{package_name}_{version}.zip"
        with zipfile.ZipFile(zipfilename, 'w') as zipf:
            for file in file_names:
                zipf.write(file)
                os.remove(file)
        
        return zipfilename

    def download_artifacts_gz(self, artifact_name: str):
        '''
        Download artifacts from the COS bucket as a zip file.
        :return: zipfile path to be downloaded/
        :rtype: string 
        '''
        print("Downloading artifacts for", artifact_name)
        
        download_url =  f"{CLOUD_OBJECT_STORAGE_URL}/{CLOUD_OBJECT_BUCKET_NAME}/{artifact_name}"
        response = requests.get(
            download_url,
            headers = {
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        if response.status_code == 200 :
            artifact_name = artifact_name.replace("/","_")
            file_path = f"{artifact_name}"
            with open(file_path, 'wb') as fh:
                fh.write(response.content)
        
        return file_path
            
     # We need to read and write to/from bulksearch bucket    
    def get_artifacts(
        self, 
        package_name: str,
        version: str,
        result_type: str,
        tool: str,
        repo: str,
        file_format: str,
        scan_type: str):
        """
        Fetch artifacts from the Cloud Object storage and get a json data.
        :param artifact_path: Cloud Object Storage URL for retrieving Object
        :type artifact_path: str
        :return: Cached file path, i.e. OUTPUT_DIR of the tool
        :rtype: json
        """
        download_url =  f"{CLOUD_OBJECT_STORAGE_URL}/{CLOUD_OBJECT_BUCKET_NAME}/{package_name}/{version}/{scan_type}_scanner.tar.gz"
        response = requests.get(
            download_url,
            headers = {
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        data = None
        try: 
            if response.status_code == 200:
                file_path = f"{package_name}_{version}_{scan_type}_scanner.tar.gz"
                with open(file_path, 'wb') as fh:
                    fh.write(response.content)
                data = self.unzip_and_get_json(zip_file_path = file_path, tool = tool, scan_type = scan_type, result_type = result_type, file_format = file_format)
                return data
            else:
                print(self.no_file, download_url)
                return data
        except Exception as e:
           print(e)

    # We need to read and write to/from bulksearch bucket
    def get_artifacts_from_bulksearch_bucket(self, artifact_path):
        """
        Fetch artifacts from the Cloud Object storage.
        :param artifact_path: Cloud Object Storage URL for retrieving Object
        :type artifact_path: str
        :return: Cached file path, i.e. OUTPUT_DIR of the tool
        :rtype: str
        """
        response = requests.get(
            artifact_path,
            headers = {
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        # Dump the file in temp output dir of the tool.
        # Create a sweeper job to periodically clean temp files in INPUT/OUTPUT folders.
        file_path = re.sub('.*?{}/'.format(self.module_bucket),'',artifact_path)
        filename = file_path.split("/")[-1]
        file_directory = re.sub('/{}'.format(filename),'',file_path)
        try:
            if response.status_code == 200:
                # crete directory if not exists
                os.makedirs(file_directory, exist_ok=True)
                with open(file_path, 'wb') as fh:
                    fh.write(response.content)
                response.filepath = file_path
            return response
        except Exception as e:
           print(e)
    
    def unzip_and_get_json (self, zip_file_path, tool, scan_type, result_type, file_format):
        '''
        Process the tar.gz file from the COS bucket and returns the json data.
        :return: json data from source and image sbom and cve details.
        :rtype: json
        '''
        extracted_folder = zip_file_path[: -len('.tar.gz')]
        file = tarfile.open(zip_file_path)
        file.extractall(extracted_folder)
        file.close()
        os.remove(zip_file_path)
        json_file = os.path.join(f"{extracted_folder}/{scan_type}", f"{tool.lower()}_{scan_type}_{result_type}_results.{file_format}")
        try:
            with open(json_file, 'r') as file_json:
                data = json.load(file_json)
                shutil.rmtree(extracted_folder)
                return data
        except FileNotFoundError as fe:
            print(f"File not found: {fe}")
            shutil.rmtree(extracted_folder)
            return None
        except Exception as e:
            print(f"Error reading file: {e}")
            shutil.rmtree(extracted_folder)
            return None


    def push_artifacts(self, artifact_path, artifact_name, content_type = "application/x-gzip"):
        """
        Store artifacts to the Cloud Object storage service.
        :param artifact_path: locally cahched artifact path. i.e. INPUT_DIR/OUTPUT_DIR of the tool. 
        :type artifact_path: str
        :param artifact_name: Actual name of the artifact to be upload.
        :type artifact_name: str
        :param content_type: Artifact content type. {"tar.gz": "application/x-gzip", ".xlsx": "application/vnd.ms-excel", "log": "text/plain"}
        :type content_type: str
        :return: Path to download artifact from the Cloud Object Storage service.
        :rtype: str
        """
        object_url = f"{CLOUD_OBJECT_STORAGE_URL}/{self.module_bucket}/{artifact_name}"
        response = requests.put(
            object_url,
            data = open(artifact_path,'rb').read(),
            headers = {
                'Content-Type': content_type,
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )

        return response


    def delete_artifacts(self,artifact_name):
        """
        Remove artifacts from COS bucket
        :return: Response of deleted artifact
        :rtype: str
        """
        object_url = f"{CLOUD_OBJECT_STORAGE_URL}/{self.module_bucket}/{artifact_name}"
        response = requests.delete(
            object_url,
            headers={
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        return response

    def push_artifacts_sbomcve(self, artifact_name, content_type = "application/json"):
        """
        Store artifacts to the Cloud Object storage service.
        :param artifact_path: locally cahched artifact path.
        :type artifact_path: str
        :param artifact_name: Actual name of the artifact to be upload.
        :type artifact_name: str
        :param content_type: Artifact content type. {"json": "application/json", ".json": "application/json", "log": "text/plain"}
        :type content_type: str
        :return: Path to download artifact from the Cloud Object Storage service.
        :rtype: str
        """
        object_url = f"{CLOUD_OBJECT_STORAGE_URL}/{self.module_bucket}/{artifact_name}"
        response = requests.put(
            object_url,
            data = open(f"{artifact_name}",'rb').read(),
            headers = {
                'Content-Type': content_type,
                'Content-Length': str(os.stat(f"{artifact_name}").st_size),
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        if response.status_code == 200:
            return object_url
        return response
    
            
    
    def get_artifacts_sbomcve(self, package_name: str):
        """
        Fetch artifacts from the Cloud Object storage and get a json data.
        :param artifact_path: Cloud Object Storage URL for retrieving Object
        :type artifact_path: str
        :return: Cached file path, i.e. OUTPUT_DIR of the tool
        :rtype: json
        """
        download_url =  f"{CLOUD_OBJECT_STORAGE_URL}/{CLOUD_OBJECT_CVE_SBOM_BUCKET}/{package_name}"
        response = requests.get(
            download_url,
            headers = {
                "Authorization": f"Bearer {self.get_auth_token()}"
            }
        )
        try: 
            if response.status_code == 200:
                file_path = f"{SBOM_CVE_DIR}/{package_name}"
                with open(file_path, 'wb') as fh:
                    fh.write(response.content)
                    return file_path
            else:
                print(self.no_file, download_url)
                return None
        except Exception as e:
           print(e)





