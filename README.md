<p align="center">
  <img src="https://www.theaiautomators.com/wp-content/uploads/2025/06/Group-2651.svg" alt="InsightsLM Logo" width="600"/>
</p>

# InsightsLM: Your Self-Hosted, Private NotebookLM Clone

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/theaiautomators/insights-lm-public?style=social)](https://github.com/theaiautomators/insights-lm-public/stargazers)
[![YouTube Video](https://img.shields.io/badge/YouTube-Watch%20the%20Build-red)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

> What if the power of a tool like NotebookLM wasn't locked away in a closed system? What if you could build a private, self-hosted clone that can be customized for your business needs, all without writing a single line of code?

That's exactly what we've done with **InsightsLM**. This project is an open-source, self-hostable alternative to NotebookLM. It's designed to be a powerful AI research tool that grounds its responses exclusively in the sources you provide, making it a reliable window into your company's knowledge base.

## About The Project

NotebookLM is one of the most powerful AI research tools available today. However, its closed-source nature limits its potential for customization and private hosting. InsightsLM was created to bridge this gap.

This isn't just a basic prototype. It's a robust application with some killer features, developed using a "vibe-coding" approach with Loveable for the Javascript frontend and a powerful backend combination of Supabase and N8N.

We are open-sourcing InsightsLM so you can install it, customize it, improve it, and even commercialize it. The ability to deploy AI agents grounded in a company's specific knowledge (a concept known as Retrieval-Augmented Generation or RAG) represents one of the biggest commercial opportunities for generative AI today.

<p align="center">
  <img src="https://www.theaiautomators.com/wp-content/uploads/2025/06/Group-2651.svg" alt="The AI Automators Logo" width="600"/>
</p>

## Join Our Community

If you're interested in learning how to customize InsightsLM or build similar applications, join our community, The AI Automators.

https://www.theaiautomators.com/

## Key Features

* **Chat with Your Documents:** Upload your documents and get instant, context-aware answers.
* **Verifiable Citations:** Jump directly to the source of the information to ensure the AI isn't hallucinating.
* **Podcast Generation:** Create audio summaries and discussions from your source materials, just like in NotebookLM.
* **Private and Self-Hosted:** Maintain complete control over your data by hosting it yourself.
* **Customizable and Extensible:** Built with modern, accessible tools, making it easy to tailor to your specific needs.
* **Low-Code/No-Code Foundation:** A testament to the power of modern AI-coding and automation platforms.

## Demo & Walkthrough

For a complete demonstration of InsightsLM, an overview of its architecture, and a step-by-step guide on how to set it up, check out our YouTube video:

[**Watch the full build and demo on YouTube!**](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

## Built With

This project is built with a modern, powerful stack:
* **Frontend:** [Loveable](https://www.loveable.dev/)
    * [Vite](https://vitejs.dev/)
    * [React](https://react.dev/)
    * [TypeScript](https://www.typescriptlang.org/)
    * [shadcn-ui](https://ui.shadcn.com/)
    * [Tailwind CSS](https://tailwindcss.com/)
* **Backend:**
    * [Supabase](https://supabase.io/) - for database, authentication, and storage.
    * [N8N](https://n8n.io/) - for workflow automation and backend logic.

## Getting Started: A Guide for No-Coders

This guide provides the quickest way to get InsightsLM up and running so you can test, customize, and experiment.

1.  **Create Supabase Account and Project**
    * Go to [Supabase.io](https://supabase.io/) and create a free account.
    * Create a new project. Make sure to save your Project URL, `anon` key, and `service_role` key. You will need these later.
2.  **Create GitHub Account & Repo from Template**
    * If you don't have one, create a free account on [GitHub](https://github.com/).
    * Navigate to the InsightsLM template repository here: [**github.com/theaiautomators/insights-lm-public**](https://github.com/theaiautomators/insights-lm-public)
    * Click the `Use this template` button to create a copy of the repository in your own GitHub account.
3.  **Import into an AI-Coding Editor (Bolt.net)**
    * Create an account on an online IDE that supports Supabase integration, like [Bolt.net](https://bolt.net/).
    * Import your newly created GitHub repository into your Bolt project.
    * Connect your Supabase project using the credentials you saved in Step 1.
    * Use the editor's built-in tools to deploy the Supabase backend (database schema, edge functions, storage buckets).
4.  **Import and Configure N8N Workflows**
    * The `/n8n` directory in this repository contains the JSON files for the required N8N workflows.
    * In your N8N instance, import these workflow files.
    * Configure the credentials for Supabase and any other services used in the workflows (e.g., OpenAI).
5.  **Add N8N Webhooks to Supabase Secrets**
    * Your N8N workflows will be triggered by webhooks. Copy the webhook URLs from your N8N canvas.
    * In your Supabase project dashboard, navigate to `Settings` -> `Secrets` and add the N8N webhook URLs as secrets. This allows the Supabase Edge Functions to securely call your N8N workflows.
6.  **Test & Customize**
    * That's it! Your instance of InsightsLM should now be live.
    * You can now test the application, upload documents, and start chatting.

## Contributing

Contributions make the open-source community an amazing place to learn, inspire, and create. Any contributions you make are greatly appreciated.

- Fork the Project
- Create your Feature Branch (git checkout -b feature/AmazingFeature)
- Commit your Changes (git commit -m 'Add some AmazingFeature')
- Push to the Branch (git push origin feature/AmazingFeature)
- Open a Pull Request

## License

Distributed under the MIT License.