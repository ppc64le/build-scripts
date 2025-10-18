
import typing
import re
from io import BytesIO
from process_bom.ca_config import BOM_TOOLS

is_operator = lambda token: token.lower().strip() == "and" or token.lower().strip() == "or"
is_not_space_or_empty = lambda test_string: test_string and not test_string.isspace()

class LicensesProcessor:
    """
    A class to process licenses and evaluate their approval status.

    Attributes:
        database_wrapper (DatabaseWrapper): An instance of the DatabaseWrapper class.
        database_name (str): The name of the database to store approved licenses.
        last_updated_attribute_name (str): The name of the attribute to store the last updated timestamp.
        cached_details (dict): A dictionary to store cached details of approved licenses.

    Methods:
        __init__(self) -> None: Initializes the LicensesProcessor class.
        add_approved_licenses(self, licenses: typing.List[str]) -> None: Adds approved licenses to the database.
        remove_approved_licenses(self, licenses: typing.List[str]) -> None: Removes approved licenses from the database.
        check_cache_validity(self) -> bool: Checks if the cached details are valid.
        update_cache(self) -> None: Updates the cached details with the latest approved licenses.
        get_approved_licenses(self) -> typing.List[str]: Returns the list of approved licenses.
        get_dependency(self, ws, dependencies, tools, green, red, row_index): Adds dependencies to an Excel sheet.
        get_scan_types(self, scan, workbook, tools, source_dependencies, image_dependecies): Adds scan types to an Excel sheet.
        download_color_coded_sheet(self, tools: str, source_dependencies: list, image_dependecies: list) -> bytes: Downloads a color-coded Excel sheet.
        evaluate_licenses(self, dependencies: list) -> list: Evaluates the licenses and their approval status.
        get_truth_value(self, input_str): Returns the truth value of a given input string.
        get_list(self, info): Returns a list of items from a given string.
        convert_to_expression(self, token_list): Converts a list of tokens to an expression.
        get_exp(self, info): Returns the evaluated expression from a given string.
        process_brackets(self, info): Processes brackets in a string.
        is_unique(self, info): Checks if a string is unique.
        is_any_operator_in_info(self, info): Checks if any operator is present in a string.
        process_expression(self, license_info): Processes an expression and evaluates it.
        eval_color_code(self, info): Evaluates the color code of a given string.
    """
    database_name = "approved_licenses"
    last_updated_attribute_name = "approved_licenses_last_updated_on"
    cached_details = {
        "last_updated_on": "",
        "approved_licenses": []
    }

    def evaluate_licenses(self, dependencies: list) -> list:
        """
        Evaluate licenses for a list of dependencies.

        Parameters: dependencies (list): A list of dependencies to evaluate licenses for.

        Returns: list: A list of dependencies with their licenses evaluated.
        """
        for dependency in dependencies:
            for tool in BOM_TOOLS:
                if tool in dependency:
                    try:
                        approved = self.eval_color_code(dependency[tool])
                    except SyntaxError:
                        approved = False
                    dependency[tool] = { "licenses": dependency[tool], "approved": approved }
        return dependencies

    def get_truth_value(self, input_str):
        """
        Returns the truth value of the input string.

        Parameters:
        input_str (str): The input string to evaluate.

        Returns:
        bool or str: The truth value of the input string if it is "True" or "False", otherwise the input string itself.
        """
        input_str = input_str.strip()
        if input_str == "True" or input_str == "False":
            return eval(input_str)
        else:
            return input_str in self.cached_details["approved_licenses"]


    def convert_to_expression(self, token_list):
        """
        Convert a list of tokens to an expression.

        Parameters:
        token_list (list): A list of tokens to be converted.

        Returns:
        str: The converted expression.
        """
        temp_list = []
        for token in token_list:
            if is_operator(token.strip()):
                temp_list.append(token.lower().strip())
            else:
                truth_value = self.get_truth_value(token)
                temp_list.append(truth_value)
        temp_list = list(map(lambda item: str(item), temp_list))
        return " ".join(temp_list)
    
    def get_list(self, info):
        """
        Returns a list of strings based on the input string.

        Args:
            info (str): The input string.

        Returns:
            list: A list of strings.
        """
        temp_list = []
        license_name = ""
        this_word = ""
        for letter in info:
            if letter.isspace():
                if is_operator(this_word):
                    if license_name.strip():
                        temp_list.append(license_name)
                        license_name = ""

                    temp_list.append(this_word)
                    this_word = ""
                else:
                    this_word = this_word + letter
                    license_name = license_name + this_word
                    this_word = ""
            else:
                this_word = this_word + letter
        license_name = license_name + this_word
        temp_list.append(license_name)
        return temp_list

    def get_exp(self, info):
        """
        Get the expression from the given info.

        Args:
            info (str): The input information.

        Returns:
            str: The calculated expression.
        """
        token_list = self.get_list(info)
        result_exp = self.convert_to_expression(token_list)
        return str(eval(result_exp))

    def process_brackets(self, info):
        """
        Process brackets in the given info string.

        Args:
            info (str): The input string containing brackets.

        Returns:
            str: The modified info string with brackets replaced by their corresponding values.
        """
        re_result = re.findall(r'\(([\w\s]+)\)', info)
        while len(re_result) > 0:
            for item in re_result:
                info = info.replace(f"({item})", self.get_exp(item))
            re_result = re.findall(r'\(([\w\s]+)\)', info)
        return info

    def is_unique(self, info):
        """
        Process brackets in the given info string.

        Args:
            info (str): The input string containing brackets.

        Returns:
            str: The modified info string with brackets replaced by their corresponding values.
        """
        for delimiter in ['(', ')', ',', 'and', 'AND', 'or', 'OR']:
            if delimiter in info:
                if delimiter == '(':
                    return not self.is_any_operator_in_info(info)
                return False
        return True

    def is_any_operator_in_info(self, info):
        """
        Check if any operator is in the given info.

        Args:
            info (str): The input string to check for operators.

        Returns:
            bool: True if any operator is found, False otherwise.
        """
        for operator in [',', 'and', 'AND', 'or', 'OR']:
            if operator in info:
                return True
        return False

    def process_expression(self, license_info):
        """
        Process the license information and return the evaluated result.

        Args:
            license_info (str): The license information to be processed.

        Returns:
            bool: The evaluated result of the license information.
        """
        info = license_info
        for token in info.split(" "):
            token = token.strip()
            if is_operator(token) or token == "True" or token == "False":
                info = info.replace(token, "*")

        licenses = list(filter(is_not_space_or_empty, info.split("*")))

        for item in licenses:
            license_info = license_info.replace(item, f" {str(self.get_truth_value(item))} ", 1)

        license_info = license_info.replace("OR", "or")
        license_info = license_info.replace("AND", "and")

        return eval(license_info)

    def eval_color_code(self, info):
        """
        Evaluate the color code based on the given information.

        Parameters:
        info (str): The information to evaluate the color code.

        Returns:
        bool: The truth value of the color code based on the given information.
        """
        if self.is_unique(info):
            return self.get_truth_value(info)
        else:
            if ',' in info:
                info = info.replace(',', ' and ')

            info = self.process_brackets(info)

            return self.process_expression(info)


