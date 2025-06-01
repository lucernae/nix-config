{
  context = {
    name = "my-awesome-project";
    nixpkgs-version = "unstable";
  };
  utils = {
    custom-func = arg: builtins.toJSON arg;
  };
}
