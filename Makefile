all: result-gitea result-github

result-github: ./example-github.nix
	nix-build $< -o $@ --argstr github_token github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

result-gitea: ./example-gitea.nix
	nix-build $< -o $@ --argstr instance "http://172.60.20.3:3000" --argstr token xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
