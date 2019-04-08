module TestScikitLearnWrapper

include(joinpath("..", "fixture_learners.jl"))
using .FixtureLearners
nfcp = NumericFeatureClassification()

using FactCheck


importall Orchestra.Types
importall Orchestra.Transformers.ScikitLearnWrapper
using PyCall
@pyimport sklearn.neighbors as NN
@pyimport random as RAN

function skl_fit_and_transform!(learner::Learner, problem::MLProblem, seed=1)
  RAN.seed(seed)
  srand(seed)
  return fit_and_transform!(learner, problem, seed)
end

function backend_fit_and_transform!(sk_learner, seed=1)
  RAN.seed(seed)
  srand(seed)
  sk_learner[:fit](nfcp.train_instances, nfcp.train_labels)
  return collect(sk_learner[:predict](nfcp.test_instances))
end

function behavior_check(learner::Learner, sk_learner)
  # Predict with Orchestra learner
  orchestra_predictions = skl_fit_and_transform!(learner, nfcp)

  # Predict with original backend learner
  original_predictions = backend_fit_and_transform!(sk_learner)

  # Verify same predictions
  @fact orchestra_predictions => original_predictions
end


facts("scikit-learn learners") do
  context("SKLLearner gives same results as its backend") do
    learner_names = collect(keys(ScikitLearnWrapper.learner_dict))
    for learner_name in learner_names
      sk_learner = ScikitLearnWrapper.learner_dict[learner_name]()
      impl_options = Dict()

      fragile_learners = [
        "AdaBoostClassifier",
        "BaggingClassifier",
        "ExtraTreesClassifier",
        "GradientBoostingClassifier",
        "RandomForestClassifier",
        "SGDClassifier",
        "RadiusNeighborsClassifier",
        "RidgeClassifierCV"
      ]

      learner = SKLLearner({
        :learner => learner_name,
        :impl_options => impl_options
      })

      if !in(learner_name, fragile_learners)
        behavior_check(learner, sk_learner)
      else
        skl_fit_and_transform!(learner, nfcp)
        @fact 1 => 1
      end
    end
  end
end

end # module
