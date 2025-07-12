import os

def merge_v_files(directory, output_file):
    with open(output_file, 'w') as outfile:
        for filename in os.listdir(directory):
            if filename.endswith('.v') and filename != 'top_tb.v':
                file_path = os.path.join(directory, filename)
                with open(file_path, 'r') as infile:
                    outfile.write(infile.read())
                    outfile.write("\n")

if __name__ == "__main__":
    directory = '.'
    output_file = 'design'
    merge_v_files(directory, output_file)
    print(f'Merged files into {output_file}')
