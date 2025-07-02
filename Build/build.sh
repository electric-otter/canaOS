#!/bin/bash
set -e

cd ..

echo "Cleaning previous build..."
rm -rf build iso canaos canaos.iso

mkdir -p build
mkdir -p iso/boot/grub

# Find all .c and .cpp files
files=$(find . \( -name "*.c" -o -name "*.cpp" \))

if [ -z "$files" ]; then
  echo "No C or C++ files found. Exiting."
  exit 1
fi

echo "Compiling C and C++ files..."
# Compile all C and C++ files to object files
obj_files=()
for f in $files; do
  # compile each file to .o in build directory
  out="build/$(basename "$f" | sed 's/\.[^.]*$/.o/')"
  gcc -c -ffreestanding -O2 -Wall -Wextra -I. -o "$out" "$f"
  obj_files+=("$out")
done

echo "Linking kernel..."
# Link objects into a multiboot kernel ELF (adjust linker script path as needed)
ld -n -o build/canaOS.elf -T linker.ld "${obj_files[@]}"

# Copy kernel to ISO directory as kernel.bin
cp build/canaOS.elf iso/boot/kernel.bin

# Compile Rust files (optional, simple approach)
rust_files=$(find . -name "*.rs")
if [ -n "$rust_files" ]; then
  echo "Compiling Rust files..."
  for f in $rust_files; do
    rustc "$f" --target x86_64-unknown-none --crate-type staticlib -o "build/$(basename "${f%.rs}.rlib")"
  done
  # You may want to add Rust objects to linking — adapt as needed
fi

echo "Creating grub.cfg..."
cat > iso/boot/grub/grub.cfg << EOF
set timeout=0
set default=0

menuentry "canaOS" {
    multiboot /boot/kernel.bin
    boot
}
EOF

echo "Generating bootable ISO..."
grub-mkrescue -o canaos.iso iso

echo "Done! Bootable ISO created as canaos.iso"

