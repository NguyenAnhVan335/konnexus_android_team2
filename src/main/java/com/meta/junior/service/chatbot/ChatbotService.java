package alan.nguyen.service.chatbot;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.context.control.ActivateRequestContext;
import jakarta.inject.Inject;

@ApplicationScoped
public class ChatbotService {

    @Inject
    AIService aiService;

    @ActivateRequestContext
    public String ask(String prompt) {
        return aiService.chat(prompt);
    }

    @ActivateRequestContext
    public String summerize(String prompt){
        return aiService.summarize(prompt);
    }
}