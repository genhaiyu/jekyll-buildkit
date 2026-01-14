# A self-hosted Jekyll build runtime for Linux (Ubuntu-first)

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/264347872-8fd87cae-80dd-4721-b60a-dbc4578eadfc.png" width="260" alt="octojekyll"></p>

![Self-Hosted](https://img.shields.io/badge/self--hosted-runtime-2aa198?style=flat)
![Reproducible](https://img.shields.io/badge/reproducible-build-268bd2?style=flat)
![Ruby](https://img.shields.io/badge/Ruby-3.1.0-b58900?style=flat)
![Sass](https://img.shields.io/badge/Sass-sassc-6c71c4?style=flat)
![Ubuntu-first](https://img.shields.io/badge/Ubuntu--first-20.04%20%7C%2022.04_LTS-859900?style=flat)
![Debian](https://img.shields.io/badge/Debian-10%20%7C%2011-b58900?style=flat)
![License](https://img.shields.io/badge/License-GPLv3-586e75?style=flat)

> The function is to provide a fixed Jekyll version for self-hosted Linux servers, and manage the compile processes instead of relying on CI platforms.

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/265168014-41ed930f-dd74-4783-8104-c55f638b8338.gif" width="560" alt="deploying"/></p>

## Documentation

The fixed version of Ruby is **3.1.0**, and all gem versions are locked by `Gemfile.lock`.
A reference [Gemfile](/runtime/Gemfile) includes the compatible dependency gems.

It installs the following components when initializing a new environment:

- RVM
- Ruby **3.1.0**
- Bundler
- Jekyll
- Nginx

Otherwise, it works as a reproducible runtime for routine deployment (older runtime environment).

## Run inside the Jekyll project

```bash
curl -sSLO https://raw.githubusercontent.com/genhaiyu/jekyll-buildkit/master/buildkit.sh \
  && chmod +x buildkit.sh \
  && ./buildkit.sh
```

## Notes

- Uses **sassc** as the Sass engine, and `sass-embedded` may cause dependency issues.
- On CentOS 7/8, SELinux may block Nginx from serving the generated site and cause `403 Forbidden` responses.

If encountering 403 Forbidden on CentOS, switch SELinux to permissive/disabled mode.

```bash
sudo vim /etc/selinux/config
```

Update `SELINUX=enforcing` to `SELINUX=disabled` or `SELINUX=permissive` in the `/etc/selinux/config` file, then reboot the system.


## License

[![GNU General Public License v3.0](https://img.shields.io/github/license/genhaiyu/jekyll-buildkit)](https://github.com/genhaiyu/jekyll-buildkit/blob/master/LICENSE)
