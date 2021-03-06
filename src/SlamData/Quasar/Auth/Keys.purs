{-
Copyright 2016 SlamData, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-}

module SlamData.Quasar.Auth.Keys where

import Prelude ((<>))

idTokenLocalStorageKey ∷ String
idTokenLocalStorageKey = "sd-auth-id-token"

keyStringLocalStorageKey ∷ String
keyStringLocalStorageKey = "sd-auth-csrf"

nonceLocalStorageKey ∷ String
nonceLocalStorageKey = "sd-auth-replay"

providerLocalStorageKey ∷ String
providerLocalStorageKey = "sd-auth-provider"

fromRedirectSuffix ∷ String
fromRedirectSuffix = "from-redirect"

hyphenatedSuffix ∷ String → String → String
hyphenatedSuffix string suffix = string <> "-" <> suffix

