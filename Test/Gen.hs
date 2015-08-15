{-# LANGUAGE OverloadedStrings    #-}
------------------------------------------------------------
-- Copyright : Ambiata Pty Ltd
-- Author : Sharif Olorin <sio@tesser.org>
-- License : BSD3
------------------------------------------------------------

module Test.Gen
    ( genRequest
    ) where

import Control.Applicative
import Data.ByteString.Char8 (ByteString)
import Data.CaseInsensitive
import Network.HTTP.Proxy.Request
import Network.HTTP.Types
import Test.QuickCheck

import qualified Data.ByteString.Char8 as BS


genRequest :: Gen Request
genRequest =
    Request <$> genHttpMethod <*> genHttpVersion <*> genHeaderList <*> genSimpleUri <*> genQueryItemList

genHttpMethod :: Gen ByteString
genHttpMethod = elements
                [ "GET", "POST", "HEAD", "PUT", "DELETE", "TRACE", "CONNECT"
                , "OPTIONS", "PATCH"
                ]

genHttpVersion :: Gen HttpVersion
genHttpVersion = elements [ http09, http10, http11 ]

genSimpleUri :: Gen ByteString
genSimpleUri = BS.concat <$> sequence
    [ elements [ "http://", "https://" ]
    , BS.intercalate "." <$> listOf1 genAscii
    , genMaybePortStr
    , pure "/"
    , BS.intercalate "/" <$> listOf genAscii
    ]

genMaybePortStr :: Gen ByteString
genMaybePortStr = oneof
    [ pure ""
    , BS.pack . (:) ':' . show <$> genPort
    ]

genPort :: Gen Int
genPort = arbitrary `suchThat` (\x -> x > 0 && x < 65536)

genHeaderList :: Gen [Header]
genHeaderList = listOf genHeader

genHeader :: Gen Header
genHeader = (,) <$> genHeaderName <*> genAscii

genQueryItemList :: Gen [QueryItem]
genQueryItemList = listOf genQueryItem

genQueryItem :: Gen QueryItem
genQueryItem = (,) <$> genAscii <*> oneof [Just <$> genAscii, pure Nothing]

genHeaderName :: Gen (CI ByteString)
genHeaderName = mk <$> genAscii

genAscii :: Gen ByteString
genAscii = BS.pack <$> listOf1 (oneof [choose ('a', 'z'), choose ('0', '9')])
