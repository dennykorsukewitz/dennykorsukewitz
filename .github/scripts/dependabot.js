const { Octokit } = require("@octokit/rest");
const base64 = require("base-64");
const fs = require("fs");

const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

// Target repositories and the corresponding files
const filesToUpdate = [
    { repo: 'dennykorsukewitz/dennykorsukewitz.github.io', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/dennykorsukewitz', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/DK4Znuny-Guide', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Sublime-AddFolderToProject', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Sublime-GitHubFileFetcher', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Sublime-QuoteWithMarker', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Znuny-Agent-Notice', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Znuny-QuickDelete', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/Znuny-UBInventory', path: '.github/dependabot/dependabot.yml' },
    { repo: 'dennykorsukewitz/generator-sublime-package', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/Node-Kimai-APIClient', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/Node-MyPlayground', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/Node-snippets', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/Node-Znuny', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-AddFolderToWorkspace', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-GitHubFileFetcher', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-MyExtensionPack', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-MyPlayground', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-QuoteWithMarker', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-RainbowColors', path: '.github/dependabot/dependabot.npm.yml' },
    { repo: 'dennykorsukewitz/VSCode-Znuny', path: '.github/dependabot/dependabot.npm.yml' },
];

async function updateDependabot() {
    for (const { repo, path } of filesToUpdate) {
        const [owner, repoName] = repo.split("/");
        const dependabotContent = fs.readFileSync(path, 'utf8');

        try {
            // First, retrieve the current content to get the SHA
            const { data: { sha } } = await octokit.repos.getContent({
                owner,
                repo: repoName,
                path: '.github/dependabot.yml',
            });

            // Update the file
            await octokit.repos.createOrUpdateFileContents({
                owner,
                repo: repoName,
                path: '.github/dependabot.yml',
                message: 'Update dependabot.yml',
                content: base64.encode(dependabotContent),
                sha,
            });
        } catch (error) {
            if (error.status === 404) {
                // Create the file if it does not exist
                await octokit.repos.createOrUpdateFileContents({
                    owner,
                    repo: repoName,
                    path: '.github/dependabot.yml',
                    message: 'Create dependabot.yml',
                    content: base64.encode(dependabotContent),
                });
            } else {
                console.error(`Error updating ${repo}:`, error);
            }
        }
    }
}

updateDependabot().catch(console.error);