final: prev: {
  emacsPackagesCustom = with final.emacsPackages; {
    emacs-claude-code = final.emacsPackages.trivialBuild {
      pname = "claude-code";
      version = "0.1.0";
      src = final.fetchFromGitHub {
        owner = "stevemolitor"; 
        repo = "claude-code.el"; 
        rev = "main"; 
       sha256 = "sha256-AW3Q5XScvT3UAmzvoMS53iZtijrii6pwvQjw+VW353w=";

      };
      packageRequires = with final.emacsPackages; [
        transient
        eat
        inheritenv
      ];
    };
    org-notion = final.emacsPackages.trivialBuild {
      pname = "org-notion";
      version = "f7265a5";
      src = final.fetchFromGitHub {
        owner = "eprapancha";
        repo = "org-notion";
        rev = "f7265a5793a4f47adc24d32b727ffe825e745b3b";
        sha256 = "sha256-FA10ZLsUwMITHVEXwfAwjvVBicxqeQzAenJgQf7mbSs=";
      };
    };
  };
}