#' install_github installs R packages directly from GitHub
#' 
#' install_github is a very lightweight function with no dependencies
#' that installs R packages from GitHub.
#' 
#' @param repo identifies the GitHub repository, i.e. username/repo. Also flexibly 
#'   accepts arguments of the form username/repo@branch.
#' @param branch identifies the branch (optional)
#' @param dependencies is a vector that indicates which type of additional 
#'   packages are also to be installed. It can include any of the values in 
#'   \code{c("Depends", "Imports", "LinkingTo", "Suggests", "Enhances")}. A 
#'   value of \code{TRUE} corresponds to \code{c("Depends", "Imports", 
#'   "LinkingTo")}. If \code{dependencies} equals \code{FALSE} no further 
#'   packages will be installed.
#' @param method specifies which method \code{download.file} uses to download 
#'   the zip archive from GitHub. Can be set to any of the values in 
#'   \code{c("auto", "wget", "libcurl", "curl", "wininet")}. When set to 
#'   \code{auto}, this function will make an educated guess.
#' @examples
#' \dontrun{install_github("jtilly/matchingR")}
install_github = function(repo, 
                          branch = if (grepl("@", repo)) gsub(".*@", "", repo) else "master", 
                          dependencies = TRUE, method = "auto") {
    
    # unix system?
    unix = Sys.info()["sysname"] %in% c("Darwin", "Linux")
    
    # select a method to download files over https
    if(method == "auto") {
        
        if(unix) {
            if(capabilities("libcurl")) {
                method = "libcurl"
            } else if (file.exists(Sys.which("wget"))) {
                method = "wget"
            } else if (file.exists(Sys.which("curl"))) {
                method = "curl"   
            } else {
                stop("Could not find method to download files over https.")
            }
        } else {
            # there's probably a way to fix this...
            if(getRversion() < "3.2") {
                stop("Need R 3.2 or higher to download files over https.")
            }
            method = "wininet"
        }
    }
    
    # assemble URL
    url = paste0("https://github.com/", gsub("@.*", "", repo), "/archive/", branch, ".zip")
    
    # create a temporary directory
    tmpdir = tempdir()
    pkg.zip = file.path(tmpdir, paste0(branch, ".zip"))
    
    # download the zip archive from GitHub
    message("Downloading ", url, " using ", method)
    # follow redirects with curl requires passing in the -L option
    download.file(url = url, destfile = pkg.zip, 
                  method = method, 
                  extra = if (method == "curl") "-L" else getOption("download.file.extra"))
    
    message("Saved as ", pkg.zip)
    if (!file.exists(pkg.zip)) {
        stop("Download failed.")
    }
    
    # extract the archive
    pkg.root = file.path(tmpdir, branch)
    unzip(pkg.zip, overwrite = TRUE, exdir = pkg.root)
    message("Extracted package to ", pkg.root)
    
    # assemble path to downloaded package
    pkg.dir = file.path(pkg.root, list.files(pkg.root)[1])
    
    # default dependencies
    if (isTRUE(dependencies)) {
        dependencies = c("Depends", "Imports", "LinkingTo")
    }
    
    # Get dependencies from the package's DESCRIPTION
    if(!is.null(dependencies)) {
        
        # http://stackoverflow.com/questions/30223957/elegantly-extract-r-package-dependencies-of-a-package-not-listed-on-cran
        dcf = read.dcf(file.path(pkg.dir, "DESCRIPTION"))
        deps = unique(gsub("\\s.*", "", trimws(unlist(strsplit(dcf[, intersect(dependencies, colnames(dcf))], ","), use.names = FALSE))))
        
        # install dependencies that aren't already installed
        deps = deps[!(deps %in% c("R", rownames(installed.packages())))]
        if(length(deps)) {
            message("Also installing: ", paste(deps))
            install.packages(deps)
        }
    }
    
    # check if the package has a configure / cleanup script and set
    # chmod on unix type systems
    if (unix) {
        for(script in c("configure", "cleanup")) {
            if (file.exists(file.path(pkg.dir, script))) {
                Sys.chmod(file.path(pkg.dir, script), mode = "0755", use_umask = TRUE)
            }
        }
    }
    
    # install the package
    install.packages(pkg.dir, repos = NULL, type = "source")
    
    # clean up
    unlink(pkg.root, recursive = TRUE, force = TRUE)
    unlink(pkg.zip, force = TRUE)
}
