# A script to automatically initial or deploy a Jekyll blog on Linux

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/264347872-8fd87cae-80dd-4721-b60a-dbc4578eadfc.png" width="260" alt="octojekyll"></p>

[![](https://img.shields.io/github/actions/workflow/status/genhaiyu/jekyll-blog-routine-deploy-script/check-build.yml)](https://github.com/genhaiyu/jekyll-buildkit/blob/master/.github/workflows/check-build.yml)
[![](https://img.shields.io/badge/CentOS_7%2C_Stream_8_x86%2F64-2aa198?style=flat&logo=github&logoColor=72f54a)]()
[![](https://img.shields.io/badge/Ubuntu_20.04%2C_22.04.2_LTS%2C_23.04_x86%2F64-bb7a02?style=flat&logo=github&logoColor=4e3e51)]()

> After each commit to the repository (including private GitHub Pages repository), and execute this script on the remote server, subsequently it will be deployed and release a Jekyll blog which depends on if it's an initial server or regularly updates.

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/265168014-41ed930f-dd74-4783-8104-c55f638b8338.gif" width="560" alt="deploying"/></p>

## Documentation

Through running the script in a `jekyll` skeleton, it checks and installs the prerequisites that include `RVM`, `Ruby` and `Nginx`.
Otherwise, it only updates, builds, deploys for routine.

- Quick steps:
  * Copy the [A Sample of Jekyll Blog](https://github.com/genhaiyu/jekyll-example) repository to a server, or choose a preferred Jekyll.
  * Enter the repository directory on the server, and build this script to automatically initial or for routine updates.

```markdown
curl -sSLO https://raw.githubusercontent.com/genhaiyu/jekyll-buildkit/master/buildkit.sh && chmod a+x deploy.sh && bash deploy.sh
```

## Encounter 403 on CentOS 7/8

To deploy a site on CentOS 7/8, and the server should disable the SELINUX setting in the `/etc/selinux/config` file.
Otherwise, the pages will give a `403 Forbidden` error.

```markdown
sudo vim /etc/selinux/config
```

Update `SELINUX=enforcing` to `SELINUX=disabled` in the `/etc/selinux/config` file, then reboot the system.

## License

[![GNU General Public License v3.0](https://img.shields.io/github/license/genhaiyu/jekyll-buildkit)](https://github.com/genhaiyu/jekyll-buildkit/blob/master/LICENSE)
