import json
import argparse

# run: 
# python bounds_json_x2.py --input your_input_file.json --output your_output_file.json

def main(input_file, output_file):
    with open(input_file, 'r') as file:
        data = json.load(file)

    for id in data:
        data[id]["horizontal"] *= 2
        data[id]["vertical"] *= 2

    with open(output_file, 'w') as file:
        json.dump(data, file, indent=2)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Double horizontal and vertical values in a JSON file.")
    parser.add_argument("--input", type=str, default="input.json", help="Input JSON file path")
    parser.add_argument("--output", type=str, default="output.json", help="Output JSON file path")
    args = parser.parse_args()

    main(args.input, args.output)
