module SlamData.Workspace.Card.BuildChart.Line.Model where

import SlamData.Prelude

import Data.Argonaut (JCursor, Json, decodeJson, (~>), (:=), isNull, jsonNull, (.?), jsonEmptyObject)
import Data.Foldable as F

import SlamData.Workspace.Card.BuildChart.Aggregation as Ag

import Test.StrongCheck.Arbitrary (arbitrary)
import Test.StrongCheck.Gen as Gen
import Test.Property.ArbJson (runArbJCursor)

type LineR =
  { dimension ∷ JCursor
  , value ∷ JCursor
  , valueAggregation ∷ Ag.Aggregation
  , secondValue ∷ Maybe JCursor
  , secondValueAggregation ∷ Maybe Ag.Aggregation
  , series ∷ Maybe JCursor
  , size ∷ Maybe JCursor
  , sizeAggregation ∷ Maybe Ag.Aggregation
  , maxSize ∷ Number
  , minSize ∷ Number
  , axisLabelAngle ∷ Number
  , axisLabelFontSize ∷ Int
  }

type Model = Maybe LineR

initialModel ∷ Model
initialModel = Nothing


eqLineR ∷ LineR → LineR → Boolean
eqLineR r1 r2 =
  F.and
    [ r1.dimension ≡ r2.dimension
    , r1.value ≡ r2.value
    , r1.valueAggregation ≡ r2.valueAggregation
    , r1.secondValue ≡ r2.secondValue
    , r1.secondValueAggregation ≡ r2.secondValueAggregation
    , r1.series ≡ r2.series
    , r1.size ≡ r2.size
    , r1.sizeAggregation ≡ r2.sizeAggregation
    , r1.maxSize ≡ r2.maxSize
    , r1.minSize ≡ r2.minSize
    , r1.axisLabelAngle ≡ r2.axisLabelAngle
    , r1.axisLabelFontSize ≡ r2.axisLabelFontSize
    ]

eqModel ∷ Model → Model → Boolean
eqModel Nothing Nothing = true
eqModel (Just r1) (Just r2) = eqLineR r1 r2
eqModel _ _ = false

genModel ∷ Gen.Gen Model
genModel = do
  isNothing ← arbitrary
  if isNothing
    then pure Nothing
    else map Just do
    dimension ← map runArbJCursor arbitrary
    value ← map runArbJCursor arbitrary
    valueAggregation ← arbitrary
    secondValue ← map (map runArbJCursor) arbitrary
    secondValueAggregation ← arbitrary
    series ← map (map runArbJCursor) arbitrary
    size ← map (map runArbJCursor) arbitrary
    sizeAggregation ← arbitrary
    maxSize ← arbitrary
    minSize ← arbitrary
    axisLabelAngle ← arbitrary
    axisLabelFontSize ← arbitrary
    pure { dimension
         , value
         , valueAggregation
         , secondValue
         , secondValueAggregation
         , series
         , size
         , sizeAggregation
         , maxSize
         , minSize
         , axisLabelAngle
         , axisLabelFontSize
         }

encode ∷ Model → Json
encode Nothing = jsonNull
encode (Just r) =
  "configType" := "line"
  ~> "dimension" := r.dimension
  ~> "value" := r.value
  ~> "valueAggregation" := r.valueAggregation
  ~> "secondValue" := r.secondValue
  ~> "secondValueAggregation" := r.secondValueAggregation
  ~> "series" := r.series
  ~> "size" := r.size
  ~> "sizeAggregation" := r.sizeAggregation
  ~> "maxSize" := r.maxSize
  ~> "minSize" := r.minSize
  ~> "axisLabelAngle" := r.axisLabelAngle
  ~> "axisLabelFontSize" := r.axisLabelFontSize
  ~> jsonEmptyObject

decode ∷ Json → String ⊹ Model
decode js
  | isNull js = pure Nothing
  | otherwise = map Just do
    obj ← decodeJson js
    configType ← obj .? "configType"
    unless (configType ≡ "line")
      $ throwError "This config is not line"
    dimension ← obj .? "dimension"
    value ← obj .? "value"
    valueAggregation ← obj .? "valueAggregation"
    secondValue ← obj .? "secondValue"
    secondValueAggregation ← obj .? "secondValueAggregation"
    series ← obj .? "series"
    size ← obj .? "size"
    sizeAggregation ← obj .? "sizeAggregation"
    maxSize ← obj .? "maxSize"
    minSize ← obj .? "minSize"
    axisLabelAngle ← obj .? "axisLabelAngle"
    axisLabelFontSize ← obj .? "axisLabelFontSize"
    pure { dimension
         , value
         , valueAggregation
         , secondValue
         , secondValueAggregation
         , series
         , size
         , sizeAggregation
         , maxSize
         , minSize
         , axisLabelAngle
         , axisLabelFontSize
         }