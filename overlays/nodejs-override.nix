self: super: {
  nodejs = super.nodejs_22;
  nodejs_22 = super.nodejs_22;
  nodejs-unwrapped = super.nodejs_22-unwrapped;
  nodePackages.npm = super.nodePackages.npm;
  nodePackages.yarn = super.nodePackages.yarn;
  nodePackages.pnpm = super.nodePackages.pnpm;
  nodePackages.corepack = super.nodePackages.corepack;
}
