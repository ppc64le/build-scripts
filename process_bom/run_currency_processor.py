import os
import sys
from process_bom.CurrencyProcessor import CurrencyProcessor

def main():
    # Read arguments passed from command line or environment
    if len(sys.argv) >= 3:
        package_name = sys.argv[1]
        version = sys.argv[2]
    else:
        package_name = os.getenv("PACKAGE_NAME")
        version = os.getenv("VERSION")

    if not package_name or not version:
        print("❌ Error: Both package_name and version must be provided.")
        sys.exit(1)

    print(f"Running CurrencyProcessor for {package_name=} and {version=}")

    # Initialize and call the method
    cp = CurrencyProcessor()
    cp.update_local_build_details_in_database(package_name, version)

if __name__ == "__main__":
    main()
