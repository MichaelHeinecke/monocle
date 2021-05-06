# Copyright (C) 2021 Monocle authors
# SPDX-License-Identifier: AGPL-3.0-or-later

# Generated by monocle-codegen. DO NOT EDIT!

from flask import request
from google.protobuf import json_format as pbjson


def config_service(app):
    from monocle.api import config_get_projects
    from monocle.messages.config_pb2 import GetProjectsRequest
    from monocle.messages.config_pb2 import GetProjectsResponse

    def get_projects_stub() -> None:
        input_data: bytes = request.get_data() or b"{}"
        input_request: GetProjectsRequest = pbjson.Parse(input_data, GetProjectsRequest())  # type: ignore
        output_resp: GetProjectsResponse = config_get_projects(input_request)
        json_resp = pbjson.MessageToJson(output_resp, preserving_proto_field_name=True)
        return app.response_class(
            response=json_resp, status=200, mimetype="application/json"
        )

    app.add_url_rule(
        "/api/1/get_projects", "GetProjects", get_projects_stub, methods=["GET", "POST"]
    )


def search_service(app):
    from monocle.api import search_suggestions
    from monocle.messages.search_pb2 import SearchSuggestionsRequest
    from monocle.messages.search_pb2 import SearchSuggestionsResponse

    def suggestions_stub() -> None:
        input_data: bytes = request.get_data() or b"{}"
        input_request: SearchSuggestionsRequest = pbjson.Parse(input_data, SearchSuggestionsRequest())  # type: ignore
        output_resp: SearchSuggestionsResponse = search_suggestions(input_request)
        json_resp = pbjson.MessageToJson(output_resp, preserving_proto_field_name=True)
        return app.response_class(
            response=json_resp, status=200, mimetype="application/json"
        )

    app.add_url_rule(
        "/api/1/suggestions", "Suggestions", suggestions_stub, methods=["GET", "POST"]
    )


def task_data_service(app):
    from monocle.api import task_data_commit, task_data_get_last_updated
    from monocle.messages.task_data_pb2 import TaskDataCommitRequest
    from monocle.messages.task_data_pb2 import TaskDataCommitResponse
    from monocle.messages.task_data_pb2 import TaskDataGetLastUpdatedRequest
    from monocle.messages.task_data_pb2 import TaskDataGetLastUpdatedResponse

    def commit_stub() -> None:
        input_data: bytes = request.get_data() or b"{}"
        input_request: TaskDataCommitRequest = pbjson.Parse(input_data, TaskDataCommitRequest())  # type: ignore
        output_resp: TaskDataCommitResponse = task_data_commit(input_request)
        json_resp = pbjson.MessageToJson(output_resp, preserving_proto_field_name=True)
        return app.response_class(
            response=json_resp, status=200, mimetype="application/json"
        )

    app.add_url_rule(
        "/api/1/task_data_commit", "Commit", commit_stub, methods=["GET", "POST"]
    )

    def get_last_updated_stub() -> None:
        input_data: bytes = request.get_data() or b"{}"
        input_request: TaskDataGetLastUpdatedRequest = pbjson.Parse(input_data, TaskDataGetLastUpdatedRequest())  # type: ignore
        output_resp: TaskDataGetLastUpdatedResponse = task_data_get_last_updated(
            input_request
        )
        json_resp = pbjson.MessageToJson(output_resp, preserving_proto_field_name=True)
        return app.response_class(
            response=json_resp, status=200, mimetype="application/json"
        )

    app.add_url_rule(
        "/api/1/task_data_get_last_updated",
        "GetLastUpdated",
        get_last_updated_stub,
        methods=["GET", "POST"],
    )
