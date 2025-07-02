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
obj_files=()
for f in $files; do
  out="build/$(basename "$f" | sed 's/\.[^.]*$/.o/')"
  gcc -c -ffreestanding -O2 -Wall -Wextra -I. -o "$out" "$f"
  obj_files+=("$out")
done

echo "Linking kernel..."
ld -n -o build/kernel.bin -T linker.ld "${obj_files[@]}"

echo "Copying Kernel boot files to ISO..."
cp -r Kernel/* iso/boot/

echo "Copying linked kernel.bin to ISO..."
cp build/kernel.bin iso/boot/

# Compile Rust files (optional)
rust_files=$(find . -name "*.rs")
if [ -n "$rust_files" ]; then
  echo "Compiling Rust files..."
  for f in $rust_files; do
    rustc "$f" --target x86_64-unknown-none --crate-type staticlib -o "build/$(basename "${f%.rs}.rlib")"
  done
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

