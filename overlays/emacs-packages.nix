final: prev: {
  emacsPackagesCustom = with final.emacsPackages; {
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
