# Gets the result of the most recent run for a workflow.

param (
    [string]$Repository,
    [string]$Branch,
    [string]$WorkflowPath
)

$conclusion = $null

$allRuns = gh api "/repos/$Repository/actions/runs" | ConvertFrom-Json
$workflowRuns = $allRuns.workflow_runs.Where({$_.path -eq $WorkflowPath -and $_.head_branch -eq $Branch})

if ($workflowRuns) {
    $conclusion = $workflowRuns[0].conclusion
}

return $conclusion