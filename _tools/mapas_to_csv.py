import os
import csv
import re

def extract_data_from_script(file_path):
    with open(file_path, 'r') as file:
        content = file.read()

    data = {}
    data['id'] = int(re.search(r'id\s*=\s*(\d+);', content).group(1))
    data['width'] = int(re.search(r'width\s*=\s*(\d+);', content).group(1))
    data['height'] = int(re.search(r'height\s*=\s*(\d+);', content).group(1))
    data['backgroundNum'] = int(re.search(r'backgroundNum\s*=\s*(\d+);', content).group(1))
    data['ambianceId'] = int(re.search(r'ambianceId\s*=\s*(\d+);', content).group(1))
    data['musicId'] = int(re.search(r'musicId\s*=\s*(\d+);', content).group(1))
    data['bOutdoor'] = re.search(r'bOutdoor\s*=\s*(true|false);', content).group(1) == 'true'
    data['capabilities'] = int(re.search(r'capabilities\s*=\s*(\d+);', content).group(1))
    data['mapData'] = re.search(r'mapData\s*=\s*"(.*?)";', content, re.DOTALL).group(1)
    data['canAggro'] = re.search(r'canAggro\s*=\s*(true|false);', content).group(1) == 'true'
    data['canUseInventory'] = re.search(r'canUseInventory\s*=\s*(true|false);', content).group(1) == 'true'
    data['canUseObject'] = re.search(r'canUseObject\s*=\s*(true|false);', content).group(1) == 'true'
    data['canChangeCharac'] = re.search(r'canChangeCharac\s*=\s*(true|false);', content).group(1) == 'true'

    return data

def process_folder(folder_path, output_csv):
    with open(output_csv, 'w', newline='') as csvfile:
        fieldnames = [
            'id', 'width', 'height', 'backgroundNum', 'ambianceId',
            'musicId', 'bOutdoor', 'capabilities', 'mapData',
            'canAggro', 'canUseInventory', 'canUseObject', 'canChangeCharac'
        ]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for root, dirs, files in os.walk(folder_path):
            if 'DoAction.as' in files:
                file_path = os.path.join(root, 'DoAction.as')
                data = extract_data_from_script(file_path)
                writer.writerow(data)

# Example usage:
folder_path = 'map_content'
output_csv = 'output.csv'
process_folder(folder_path, output_csv)
