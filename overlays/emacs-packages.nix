final: prev: {
  emacsPackagesCustom = with final.emacsPackages; {
    mu4e-dashboard = final.emacsPackages.trivialBuild {
      pname = "mu4e-dashboard";
      version = "0.1.0";
      src = final.fetchFromGitHub {
        owner = "rougier"; 
        repo = "mu4e-dashboard"; 
        rev = "main"; 
        sha256 = "sha256-bCelxaT+qaR2W80Cr591A4cRycIFJmXjeY8/aqIpl5g=";
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
        sha256 = "sha256-RXs7iKWtUz1ZmjAWL0pZ8JdWMxNS85P3WZWLUR85ExQ=";
      };
      packageRequires = with final.emacsPackages; [
        transient
        eat
      ];
    };
  };
}
