Rails.application.routes.draw do
  get "mediator_cases/show"
  get "third_party_mediations/index"
  get "manage_cases/index"
  root "sessions#new"  # Home Page

  # Authentication
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  # Dashboard Pages
  get "/dashboard", to: "dashboard#index", as: "dashboard"
  get "dashboard/landlord", to: "dashboard#landlord", as: "landlord_dashboard"
  get "dashboard/tenant", to: "dashboard#tenant", as: "tenant_dashboard"
  get "dashboard/admin", to: "dashboard#admin", as: "admin_dashboard"
  get "dashboard/mediator", to: "dashboard#mediator", as: "mediator_dashboard"

  # User Signup and Account Management
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  get "/account", to: "account#show"
  get "/account/edit", to: "account#edit"
  patch "/account", to: "account#update"

  get "messages/tenant_show/:conversation_id", to: "messages#show", as: "tenant_show"
  get "messages/landlord_show/:conversation_id", to: "messages#show", as: "landlord_show"

  # get '/complete_screening', to: 'screenings#complete_screening'

  get "screenings/new/:conversation_id", to: "screenings#new", as: "new_screening"

  get "messages/tenant_index", to: "messages#tenant_index", as: "tenant_index"
  get "messages/landlord_index", to: "messages#landlord_index", as: "landlord_index"

  get "documents/download/:id", to: "documents#download", as: "download_file"
  get "documents/:id/view", to: "documents#show", as: "view_file"

  get "documents/generate", to: "documents#generate", as: "generate_file"
  get "documents/landlord_index", to: "documents#landlord_index", as: "landlord_documents"

  post "documents/select_template", to: "documents#select_template", as: "select_template"

  get "proposal_generation/:template", to: "documents#proposal_generation", as: "proposal_generation"

  get "intake_questions/new", to: "intake_questions#new", as: "new_intake_question"
  post "intake_questions", to: "intake_questions#create", as: "intake_questions"


  get  "/documents/template_preview/:conversation_id", to: "documents#intake_template_view", as: :intake_template_view
  post "/documents/template_generate", to: "documents#generate_filled_template", as: :generate_filled_template


  # Resources
  resources :messages, only: [ :index, :show, :create, :destroy ] do
    patch :request_mediator, on: :member
  end

  resources :mediator_messages, only: [ :create ]


  resources :documents, only: [ :index, :show, :create, :destroy ]
  resources :resources, only: [ :index ]

  # System Data
  resource :system_data, only: [ :show ]

  # Mediations and Related Actions
  resources :mediations, only: [ :new, :create, :edit, :update, :destroy ] do
    post :accept, on: :member
    post :respond, on: :member
  end

  # Allow a tenant or landlord table to see previous mediations
  get "/mediation_summary/:id", to: "messages#summary", as: "mediation_summary"

  # Allow tenant or landlord to terminate a negotiation or mediation
  patch "/end_mediation/:id", to: "mediations#end_conversation", as: "end_mediation"

  # Allow tenant and landlord to fill out good faith question
  get "/good_faith_response/:id", to: "mediations#good_faith_form", as: "good_faith_response"
  patch "/good_faith_response/:id", to: "mediations#update_good_faith"
  get "/mediation_ended_prompt/:id", to: "mediations#prompt_screen", as: "mediation_ended_prompt"


  # Allow third party mediator to view cases
  resources :third_party_mediations, only: [ :index ]
  resources :mediator_cases, only: [ :show ]

  resources :screenings, only: [ :new, :create ]

  namespace :admin do
    # Admin Mediator Accounts Controller
    resources :accounts, only: [ :index, :create, :update ], controller: "accounts"

    # This matches the /mediations path in the navbar
    get "mediations", to: "flagged_mediations#index"
    get "mediations/:id", to: "flagged_mediations#show", as: "flagged_mediation"
    patch "mediations/:id/reassign", to: "flagged_mediations#reassign", as: "reassign_mediator"
  end

  # admin unflag
  patch "/admin/mediations/:id/unflag", to: "admin/flagged_mediations#unflag", as: "admin_unflag_mediation"

  # Messages related ActionCable
  mount ActionCable.server => "/cable"
end
