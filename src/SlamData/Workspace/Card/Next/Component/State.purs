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

module SlamData.Workspace.Card.Next.Component.State where

import SlamData.Prelude

import Data.Lens (Lens', lens)

import SlamData.Workspace.Card.Port (Port)

import SlamData.Workspace.Card.Next.NextAction (NextAction)

type State =
  { input ∷ Maybe Port
  , presentAddCardGuide ∷ Boolean
  , actions ∷ Array NextAction
  , previousActions ∷ Array NextAction
  , filterString ∷ String
  }

initialState ∷ State
initialState =
  { input: Nothing
  , presentAddCardGuide: false
  , actions: []
  , previousActions: [ ]
  , filterString: ""
  }

_input ∷ ∀ a r. Lens' { input ∷ a | r } a
_input = lens _.input (_ { input = _ })

_actions ∷ ∀ a r. Lens' { actions ∷ a |r } a
_actions = lens _.actions (_ { actions = _ })

_previousActions ∷ ∀ a r. Lens' { previousActions ∷ a | r} a
_previousActions = lens _.previousActions (_ { previousActions = _ })

_presentAddCardGuide ∷ ∀ a r. Lens' { presentAddCardGuide ∷ a | r } a
_presentAddCardGuide = lens _.presentAddCardGuide (_ { presentAddCardGuide = _ })

_filterString ∷ ∀ a r. Lens' { filterString ∷ a | r } a
_filterString = lens _.filterString (_ { filterString = _ })
