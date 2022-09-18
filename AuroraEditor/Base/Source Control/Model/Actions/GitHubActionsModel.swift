//
//  GitHubActionsModel.swift
//  AuroraEditor
//
//  Created by Nanashi Li on 2022/09/13.
//  Copyright © 2022 Aurora Company. All rights reserved.
//

import Foundation

class GitHubActions: ObservableObject {

    enum State {
        case loading
        case error
        case success
        case repoFailure
    }

    @Published
    var state: State = .loading

    let workspace: WorkspaceDocument

    @Published
    var workflows: [Workflow] = []

    @Published
    var workflowRuns: [WorkflowRun] = []

    @Published
    var workflowJobs: [JobSteps] = []

    @Published
    private var workflowJob: [Jobs] = []

    @Published
    var repoOwner: String = ""

    @Published
    var repo: String = ""

    init(workspace: WorkspaceDocument) {
        self.workspace = workspace

        getRepoInformation()
    }

    func fetchWorkflows() {
        AuroraNetworking().request(path: NetworkingConstant.workflows(repoOwner,
                                                                      repo),
                                   method: .GET,
                                   parameters: nil,
                                   completionHandler: { result in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                guard let workflows = try? decoder.decode(Workflows.self, from: data) else {
                    return
                }
                DispatchQueue.main.async {
                    self.state = .success
                    self.workflows = workflows.workflows
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.state = .error
                }
                Log.error(error)
            }
        })
    }

    func fetchWorkflowRuns(workflowId: String) {
        AuroraNetworking().request(path: NetworkingConstant.workflowRuns(repoOwner,
                                                                         repo,
                                                                         workflowId: workflowId),
                                   method: .GET,
                                   parameters: nil,
                                   completionHandler: { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let workflowRuns = try decoder.decode(WorkflowRuns.self, from: data)
                    DispatchQueue.main.async {
                        self.workflowRuns = workflowRuns.workflow_runs
                    }
                } catch {
                    Log.debug("Error: \(error)")
                }
            case .failure(let error):
                Log.error(error)
            }

        })
    }

    func fetchWorkflowJobs(runId: String) {
        AuroraNetworking().request(path: NetworkingConstant.workflowJobs(repoOwner,
                                                                         repo,
                                                                         runId: runId),
                                   method: .GET,
                                   parameters: nil,
                                   completionHandler: { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let jobs = try decoder.decode(Job.self, from: data)
                    DispatchQueue.main.async {
                        self.workflowJob = jobs.jobs
                        for job in jobs.jobs {
                            self.workflowJobs = job.steps
                        }
                    }
                } catch {
                    Log.debug("Error: \(error)")
                }
            case .failure(let error):
                Log.error(error)
            }
        })
    }

    func reRunWorkflowJobs() {
        AuroraNetworking().request(path: NetworkingConstant.reRunJob(repoOwner,
                                                                     repo,
                                                                     jobId: String(workflowJob[0].id)),
                                   method: .POST,
                                   parameters: nil,
                                   completionHandler: { result in
            switch result {
            case .success:
                Log.debug("Succeffully Re-Run job: \(self.workflowJob[0].id)")
            case .failure(let error):
                Log.error(error)
            }
        })
    }

    func downloadWorkflowLogs(jobId: String) {
        AuroraNetworking().request(path: NetworkingConstant.reRunJob(repoOwner,
                                                                     repo,
                                                                     jobId: jobId),
                                   method: .POST,
                                   parameters: nil,
                                   completionHandler: { result in
            switch result {
            case .success:
                Log.debug("Succeffully Downloaded Workflow Logs for: \(jobId)")
            case .failure(let error):
                Log.error(error)
            }
        })
    }

    func getRepoInformation() {
        do {
            let remote = try Remote().getRemoteURL(directoryURL: workspace.workspaceURL(),
                                                   name: "origin")
            let remoteURL = URL(string: remote!)

            // As caution we check if the origin contains git@ so we can fetch the repo
            // info in one of two ways.
            if remote?.contains("git@") ?? false {
                // git@github.com-angelk90:AuroraEditor/AuroraEditor.git
                let splitGit = remote?.split(separator: ":")
                let splitRepoDetails = splitGit?[1].split(separator: "/")

                repoOwner = splitRepoDetails?[0].description ?? ""
                repo = splitRepoDetails?[1].description.replacingOccurrences(of: ".git", with: "") ?? ""
            } else {
                let remoteSplit = remoteURL?.pathComponents
                repoOwner = remoteSplit?[1] ?? ""

                let repoValue = remoteSplit?[2] ?? ""
                repo = repoValue.replacingOccurrences(of: ".git", with: "")
            }
        } catch {
            Log.error("Failed to get project remote URL.")
            DispatchQueue.main.async {
                self.state = .repoFailure
            }
        }
    }
}
