mkdir -p ~/development
curl -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/beta/linux/flutter_linux_3.10.0-1.5.pre-beta.tar.xz
tar xf flutter.tar.xz -C ~/development
rm -f flutter.tar.xz
echo 'export PATH=~/development/flutter/bin:$PATH' >> $BASH_ENV