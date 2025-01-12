all: result-gitea result-github

result-github: ./example-github.nix
	nix-build $< --argstr github_token github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -o $@

result-gitea: ./example-gitea.nix
	nix-build $< -o $@
