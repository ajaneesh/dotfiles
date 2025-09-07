final: prev: {
  emacsPackagesCustom = with final.emacsPackages; {
    mu4e-dashboard = final.emacsPackages.trivialBuild {
      pname = "mu4e-dashboard";
      version = "0.1.0";
      src = final.fetchFromGitHub {
        owner = "rougier"; 
        repo = "mu4e-dashboard"; 
        rev = "main"; 
        sha256 = "sha256-neRNHOI+4mRG04DcY1l9SS8kJGf9Zjb+RmaBWtx21/o=";
      };
      packageRequires = with final.emacsPackages; [
        async
        mu4e
      ];
    };
    emacs-claude-code = final.emacsPackages.trivialBuild {
      pname = "claude-code";
      version = "0.1.0";
      src = final.fetchFromGitHub {
        owner = "stevemolitor"; 
        repo = "claude-code.el"; 
        rev = "main"; 
        sha256 = "sha256-neRNHOI+4mRG04DcY1l9SS8kJGf9Zjb+RmaBWtx21/o=";
      };
      packageRequires = with final.emacsPackages; [
        transient
        eat
      ];
    };
  };
}
