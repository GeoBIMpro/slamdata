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

module SlamData.Workspace (main) where

import SlamData.Prelude

import Control.Coroutine (runProcess, await, ($$))
import Control.Coroutine.Aff (produce)
import Control.Monad.Aff (Aff, forkAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Ref as Ref
import Control.Monad.Eff.Class (liftEff)
import Control.UI.Browser as Browser

import Ace.Config as AceConfig

import Data.Nullable (toMaybe)

import DOM.HTML.Document (body)
import DOM.HTML (window)
import DOM.HTML.Window (document)
import DOM.Node.Element (setClassName)
import DOM.HTML.Types (htmlElementToElement)

import Halogen (Driver, runUI, parentState, interpret)
import Halogen.Util (runHalogenAff, awaitBody)

import SlamData.Analytics as Analytics
import SlamData.Config as Config
import SlamData.Effects (SlamDataRawEffects, SlamDataEffects)
import SlamData.Monad (runSlam)
import SlamData.Wiring (Wiring(Wiring), makeWiring)
import SlamData.Workspace.AccessType as AT
import SlamData.AuthenticationMode as AuthenticationMode
import SlamData.Workspace.Action (Action(..), toAccessType)
import SlamData.Workspace.Component as Workspace
import SlamData.Workspace.Deck.Component as Deck
import SlamData.Workspace.Routing (Routes(..), routing)
import SlamData.Workspace.StyleLoader as StyleLoader

import Routing as Routing

import Utils.Path as UP

data RouterState = RouterState Routes Wiring (Driver Workspace.QueryP SlamDataRawEffects)

main ∷ Eff SlamDataEffects Unit
main = do
  AceConfig.set AceConfig.basePath (Config.baseUrl ⊕ "js/ace")
  AceConfig.set AceConfig.modePath (Config.baseUrl ⊕ "js/ace")
  AceConfig.set AceConfig.themePath (Config.baseUrl ⊕ "js/ace")
  runHalogenAff do
    forkAff Analytics.enableAnalytics
    forkAff routeSignal
  StyleLoader.loadStyles

routeSignal ∷ Aff SlamDataEffects Unit
routeSignal = do
  runProcess (routeProducer $$ routeConsumer Nothing)

  where
  routeProducer = produce \emit →
    Routing.matches' UP.decodeURIPath routing \_ → emit ∘ Left

  routeConsumer state = do
    new ← await
    case new, state of
      -- Initialize the Workspace component
      WorkspaceRoute path deckId action varMaps, Nothing → do
        wiring ← lift $ makeWiring path varMaps
        let
          st = Workspace.initialState (Just "4.0")
          ui = interpret (runSlam wiring) Workspace.comp
        driver ← lift $ runUI ui (parentState st) =<< awaitBody
        lift $ setupWorkspace new wiring driver
        routeConsumer (Just (RouterState new wiring driver))

      -- Reload the page on path change
      WorkspaceRoute path _ _ _, Just (RouterState (WorkspaceRoute path' _ _ _) _ _) | path ≠ path' →
        lift $ liftEff Browser.reload

      -- Transition Workspace
      WorkspaceRoute path deckId action varMaps, Just (RouterState old wiring driver) →
        case old of
          WorkspaceRoute path' deckId' action' varMaps'
            | path ≡ path' ∧ deckId ≡ deckId' ∧ action ≡ action' ∧ varMaps ≡ varMaps' →
                routeConsumer (Just (RouterState new wiring driver))
          _ → do
            lift $ setupWorkspace new wiring driver
            routeConsumer (Just (RouterState new wiring driver))

  setupWorkspace new@(WorkspaceRoute _ deckId action varMaps) (Wiring wiring) driver = do
    driver $ Workspace.toWorkspace $ Workspace.SetVarMaps varMaps
    when (toAccessType action ≡ AT.ReadOnly) do
      isEmbedded ←
        liftEff $ Browser.detectEmbedding
      let
        bodyClass =
          if isEmbedded
            then "sd-workspace-page sd-embedded"
            else "sd-workspace-page"
      void
        $ liftEff
        $ traverse (setClassName bodyClass ∘ htmlElementToElement)
        ∘ toMaybe
        =<< body
        =<< document
        =<< window

    forkAff case action of
      Load accessType → do
        liftEff
          $ Ref.writeRef wiring.allowedAuthenticationModes
          $ AuthenticationMode.allowedAuthenticationModesForAccessType accessType
        driver $ Workspace.toWorkspace $ Workspace.Load deckId accessType
      Exploring fp → do
        driver $ Workspace.toWorkspace $ Workspace.Reset
        driver $ Workspace.toDeck $ Deck.ExploreFile fp
      New → do
        driver $ Workspace.toWorkspace $ Workspace.Reset
