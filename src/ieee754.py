import struct

def float_to_float16_hex(f: float) -> str:
  if f == 0.0:
    if struct.pack('>f', f)[0] & 0x80:
      return "8000"
    else:
      return "0000"
  
  packed = struct.pack('>f', f)
  i = struct.unpack('>I', packed)[0]
  sign = (i >> 31) & 0x1
  exponent = (i >> 23) & 0xFF
  fraction = i & 0x7FFFFF
  
  if exponent == 0xFF:  # NaN or Inf
    if fraction:  # NaN
      return "7e00" if sign == 0 else "fe00"
    else:  # Inf
      return "7c00" if sign == 0 else "fc00"
  
  if exponent == 0:  # Denormalized in single-precision
    return "8000" if sign else "0000"
  
  new_exponent = exponent - 127 + 15
  
  if new_exponent <= 0:  # Underflow to zero
    return "8000" if sign else "0000"
  if new_exponent >= 0x1F:  # Overflow to Inf
    return "7c00" if sign == 0 else "fc00"
  
  base = fraction >> 13
  rounding_bits = fraction & 0x1FFF
  
  if rounding_bits < 0x1000:
    new_fraction = base
  elif rounding_bits > 0x1000:
    new_fraction = base + 1
  else:  # Exactly halfway
    new_fraction = base + 1 if (base & 1) else base
  
  if new_fraction >= 0x400:  # Carry over to exponent
    new_exponent += 1
    new_fraction = 0
    if new_exponent >= 0x1F:
      return "7c00" if sign == 0 else "fc00"
  else:
    new_fraction = new_fraction & 0x3FF
  
  result = (sign << 15) | (new_exponent << 10) | new_fraction
  return f"{result:04X}"

def float_to_float32_hex(f: float) -> str:
  packed = struct.pack('>f', f)
  i = struct.unpack('>I', packed)[0]
  return f"{i:08X}"

def main():
  try:
    num = float(input("Enter a floating-point number: "))
    half_hex = float_to_float16_hex(num)
    single_hex = float_to_float32_hex(num)
    print(f"Half-precision (16-bit): 0x{half_hex}")
    print(f"Single-precision (32-bit): 0x{single_hex}")
  except ValueError:
    print("Invalid input. Please enter a valid floating-point number.")

if __name__ == "__main__":
  main()
