# install_github [![Build Status](https://travis-ci.org/jtilly/install_github.svg?branch=gh-pages)](https://travis-ci.org/jtilly/install_github)

Simple lightweight installer for R packages from GitHub. This function imitates the behavior of the popular [devtools::install_github](https://github.com/hadley/devtools), yet it has no external dependencies. This function may be useful when you quickly want to install an R package from GitHub, but don't have the devtools package installed. This function downloads any desired R package from GitHub and installs any dependencies before installing the package itself.

### Example

```r
source("http://jtilly.io/install_github/install_github.R")
install_github("jtilly/matchingR")
```
