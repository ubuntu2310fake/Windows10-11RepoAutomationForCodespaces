#!/bin/bash

# Cập nhật danh sách gói và cài đặt QEMU-KVM
echo "Đang cập nhật danh sách gói..."
sudo apt update
sudo apt install -y qemu-kvm unzip cpulimit python3-pip
if [ $? -ne 0 ]; then
    echo "Lỗi khi cập nhật và cài đặt các gói cần thiết. Vui lòng kiểm tra lại."
    exit 1
fi

# Kiểm tra xem /mnt đã được mount hay chưa
echo "Kiểm tra phân vùng đã được mount vào /mnt..."
if mount | grep "on /mnt " > /dev/null; then
    echo "Phân vùng đã được mount vào /mnt. Tiếp tục..."
else
    echo "Phân vùng chưa được mount. Đang tìm phân vùng lớn hơn 500GB..."
    partition=$(lsblk -b --output NAME,SIZE,MOUNTPOINT | awk '$2 > 500000000000 && $3 == "" {print $1}' | head -n 1)

    if [ -n "$partition" ]; then
        echo "Đã tìm thấy phân vùng: /dev/$partition"
        sudo mount "/dev/${partition}1" /mnt
        if [ $? -ne 0 ]; then
            echo "Lỗi khi mount phân vùng. Vui lòng kiểm tra lại."
            exit 1
        fi
        echo "Phân vùng /dev/$partition đã được mount vào /mnt."
    else
        echo "Không tìm thấy phân vùng có dung lượng lớn hơn 500GB chưa được mount. Vui lòng kiểm tra lại."
        exit 1
    fi
fi

# Hiển thị menu lựa chọn hệ điều hành
echo "Chọn hệ điều hành để chạy VM, một số hđh sẽ được cập nhật trong tương lai:"
echo "1. Windows 11 23H2 (22631.2861) bản gốc chính chủ M$"
echo "2. Ubuntu 22.04 LTS (có quyền SSH, cài Tài Scale để chạy SSH và mật khẩu là 1; username runner)"
echo "3. Windows 11 24H2 gốc"
echo "4. UEFI 4 Windows OS (Windows 11 23H2; Windows 10 22H2; Windows 8.1; Windows 7)"

read -p "Nhập lựa chọn của bạn: " user_choice

if [ "$user_choice" -eq 1 ]; then
    echo "Bạn đã chọn Windows 11 23H2 (22631.2861)."
    file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiIyMWZlYWNmYi0xMWY5LTRkMTEtOGM2OC0xMTQ5YmY1NmY2YzIiLCJtb2RlIjoiciIsImZpbGVuYW1lIjoid2luMTFtb2RyZHB3Zl8xLjBfcWVtdV9hbWQ2NC5ib3gifQ.WYMn2onERXAiIk9BHyZtMJZZirZS6H9tzJAC5Sj8KIA"
    file_name="/mnt/a.qcow2"
elif [ "$user_choice" -eq 2 ]; then
    echo "Bạn đã chọn Ubuntu 22.04 LTS."
    file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiI1ZGQ1NmM1OC04ZDQ4LTQ0NzgtOWE1Zi0wYjNmYzgyYzRiNTkiLCJtb2RlIjoiciIsImZpbGVuYW1lIjoidWJ1bnR1c2VydmVyMjJfMC4wX3FlbXVfYW1kNjQuYm94In0.tYprxQPqKwTPaqlfna0u7rIlpD3WYbK03haABvT3KQk"
    file_name="/mnt/a.qcow2"
elif [ "$user_choice" -eq 3 ]; then
    echo "Bạn đã chọn Windows 11 24H2 gốc."
    file_url="https://api.cloud.hashicorp.com/vagrant-archivist/v1/object/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJsaW51eHVzZXJzZmFrZS9XaW5kb3dzMTEyNEgyLzI0LjIvV2luMTEyNEgyL2QyOTQwOWVhLWFjY2MtMTFlZi05NGM4LTVhOGNhNzBiNzRhNSIsIm1vZGUiOiJyIiwiZmlsZW5hbWUiOiJXaW5kb3dzMTEyNEgyXzI0LjJfV2luMTEyNEgyX2FtZDY0LmJveCJ9.7DD39XJxF8PjIdhHcuEABTPiZbPgq_CEgVHrV9ka_eg"
    file_name="/mnt/a.qcow2"
elif [ "$user_choice" -eq 4 ]; then
    echo "Bạn đã chọn UEFI 4 Windows OS."
    file_url="https://www.dropbox.com/scl/fi/cm4kqg5f5iis40bzmy7yo/windualboot.qcow2?rlkey=0aybiajbpqve86lpjvu5ah9x2&dl=1"
    file_name="/mnt/a.qcow2"
else
    echo "Lựa chọn không hợp lệ. Vui lòng chạy lại script và chọn 1 hoặc 2."
    exit 1
fi

# Tải file Qcow2
echo "Đang tải file $file_name từ $file_url..."
wget -O "$file_name" "$file_url"
if [ $? -ne 0 ]; then
    echo "Lỗi khi tải file. Vui lòng kiểm tra kết nối mạng hoặc URL."
    exit 1
fi

# Khởi chạy máy ảo với KVM
echo "Đang khởi chạy máy ảo..."
echo "Đã khởi động VM thành công vui lòng tự cài ngrok và mở cổng 5900"
sudo cpulimit -l 80 -- sudo kvm \
    -cpu host,+topoext,hv_relaxed,hv_spinlocks=0x1fff,hv-passthrough,+pae,+nx,kvm=on,+svm \
    -smp 2,cores=2 \
    -M q35,usb=on \
    -device usb-tablet \
    -m 4G \
    -device virtio-balloon-pci \
    -vga virtio \
    -net nic,netdev=n0,model=virtio-net-pci \
    -netdev user,id=n0,hostfwd=tcp::3389-:3389 \
    -boot c \
    -device virtio-serial-pci \
    -device virtio-rng-pci \
    -enable-kvm \
    -drive file=/mnt/a.qcow2 \
    -drive if=pflash,format=raw,readonly=off,file=/usr/share/ovmf/OVMF.fd \
    -uuid e47ddb84-fb4d-46f9-b531-14bb15156336 \
    -vnc :0
