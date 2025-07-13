import os

def merge_v_files(directory, output_file):
  with open(output_file, 'w') as outfile:
    for filename in os.listdir(directory):
      if filename.endswith('.v') and filename != 'top_tb.v' and filename != 'design.v':
        file_path = os.path.join(directory, filename)
        with open(file_path, 'r') as infile:
          outfile.write(infile.read())
          outfile.write("\n")

if __name__ == "__main__":
  merge_v_files('.', 'design.v')
  print('READY')