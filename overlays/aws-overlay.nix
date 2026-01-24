self: super: {
  awscli2 = super.awscli2.overridePythonAttrs (oldAttrs: {
    doCheck = false;
  });
}
