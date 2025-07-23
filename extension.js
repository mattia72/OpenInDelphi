const vscode = require('vscode');
const { DelphiCommander } = require('./delphiCommander');

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
	console.log('Congratulations, your extension "OpenInDelphi" is now active!');
	const disposable = vscode.commands.registerCommand('openindelphi.openCurrentFileInDelphi', DelphiCommander.openCurrentFileInDelphi);
	context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
function deactivate() { }

module.exports = {
	activate,
	deactivate
}
