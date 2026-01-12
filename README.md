# A stable Jekyll build runtime for Ubuntu

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/264347872-8fd87cae-80dd-4721-b60a-dbc4578eadfc.png" width="260" alt="octojekyll"></p>

[![](https://img.shields.io/github/actions/workflow/status/genhaiyu/jekyll-buildkit/check-build.yml)](https://github.com/genhaiyu/jekyll-buildkit/blob/master/.github/workflows/check-build.yml)
[![](https://img.shields.io/badge/Ubuntu_20.04%2C_22.04_LTS_x86%2F64-bb7a02?style=flat&logo=github&logoColor=4e3e51)]()

> This buildkit is for deploying a fixed Jekyll build environment on Ubuntu.
> It locks the Ruby version, and all dependencies must be compatible with this fixed toolchain.
>
> Uses **sassc** as the Sass engine.  
> Gemfiles based on `sass-embedded` are not supported and may cause dependency issues.

<p align="center"><img src="https://user-images.githubusercontent.com/17850202/265168014-41ed930f-dd74-4783-8104-c55f638b8338.gif" width="560" alt="deploying"/></p>

## Documentation

The fixed version of Ruby is **3.1.0**, and all gem versions are locked by `Gemfile.lock`.
A reference [Gemfile](/runtime/Gemfile) is provided to define the compatible dependency gems.

It installs the following components when initializing a new environment:

- RVM
- Ruby **3.1.0**
- Bundler
- Jekyll
- Nginx

Otherwise, it works as a reproducible runtime for routine deployment (older runtime environment).

## Quick start (Ubuntu)

```bash
curl -sSLO https://raw.githubusercontent.com/genhaiyu/jekyll-buildkit/master/buildkit.sh \
  && chmod +x buildkit.sh \
  && ./buildkit.sh
```

## License

[![GNU General Public License v3.0](https://img.shields.io/github/license/genhaiyu/jekyll-buildkit)](https://github.com/genhaiyu/jekyll-buildkit/blob/master/LICENSE)
