const fs = require("node:fs");
const path = require("node:path");
const { createRequire } = require("node:module");

function normalizeProjects(nodes) {
  return Object.fromEntries(
    Object.entries(nodes)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([name, node]) => [
        name,
        Object.keys(node?.data?.targets || node?.targets || {}).sort((left, right) => left.localeCompare(right)),
      ])
  );
}

async function readWorkspaceProjects(workspaceRoot) {
  const graphPath = path.join(workspaceRoot, ".nx", "workspace-data", "project-graph.json");

  if (fs.existsSync(graphPath)) {
    const graph = JSON.parse(fs.readFileSync(graphPath, "utf8"));
    const nodes = graph.graph?.nodes || graph.nodes || {};
    return normalizeProjects(nodes);
  }

  const requireFromWorkspace = createRequire(path.join(workspaceRoot, "package.json"));
  const { createProjectGraphAsync, readProjectsConfigurationFromProjectGraph } = requireFromWorkspace("nx/src/devkit-exports");
  const graph = await createProjectGraphAsync();
  const projects = readProjectsConfigurationFromProjectGraph(graph).projects;

  return Object.fromEntries(
    Object.entries(projects)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([name, config]) => [
        name,
        Object.keys(config.targets || {}).sort((left, right) => left.localeCompare(right)),
      ])
  );
}

(async () => {
  const workspaceRoot = path.resolve(process.argv[2] || process.cwd());
  const result = await readWorkspaceProjects(workspaceRoot);
  process.stdout.write(JSON.stringify(result));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
