{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- Generated by monocle-codegen. DO NOT EDIT!

-- |
-- Copyright: (c) 2021 Monocle authors
-- SPDX-License-Identifier: AGPL-3.0-only
module Monocle.Api.HTTP (MonocleAPI, server) where

import Monocle.Api.Env
import Monocle.Api.PBJSON (PBJSON)
import Monocle.Api.Server (searchChangesQuery, searchFields)
import Monocle.Search (ChangesQueryRequest, ChangesQueryResponse, FieldsRequest, FieldsResponse)
import Servant

type MonocleAPI =
  "api" :> "2" :> "search_fields" :> ReqBody '[JSON] FieldsRequest :> Post '[PBJSON, JSON] FieldsResponse
    :<|> "api" :> "2" :> "search" :> "changes" :> ReqBody '[JSON] ChangesQueryRequest :> Post '[PBJSON, JSON] ChangesQueryResponse

server :: ServerT MonocleAPI AppM
server =
  searchFields
    :<|> searchChangesQuery
