# final diversity/scale figures and models
source("R/diversity_data_prep.R")
library(lme4)
library(ggpubr)
library(car)

# data mongering ===============================================================

prev_year_div <- all_scales %>% 
  mutate(year = as.numeric(year)) %>%
  filter(nspp_exotic == 0) %>%
  dplyr::select(year, plotID, scale, subplotID, site,
                prev_shannon_total=shannon_total, 
                prev_nspp_total=nspp_total, 
                prev_shannon_native=shannon_native, 
                prev_nspp_native = nspp_native) %>%
  mutate(year = year+1) %>%
  left_join(all_scales%>% 
              mutate(year = as.numeric(year)),
            by = c("plotID", "subplotID", "year", "scale", "site"))

# models =======================================================================

m0<-all_scales %>%
  mutate(invaded = ifelse(invaded=="invaded",1,0)) %>%
  lme4::glmer(invaded ~ nspp_native * scale+ (1|site), 
              data = ., family = "binomial")

# this is the ggplot model, basically... not sure how to compare glm and glmer
m1<-all_scales %>%
  mutate(invaded = ifelse(invaded=="invaded",1,0)) %>%
  glm(invaded ~ nspp_native * scale, 
              data = ., family = "binomial")
#not sure what to think about this stuff
vif(m0)
vif(m1)
AIC(m0,m1)
anova(m0,m1)

prev_year_div%>%
  mutate(invaded = ifelse(invaded=="invaded",1,0), 
         prev_nspp_native = scale(prev_nspp_native)) %>%
  lme4::glmer(invaded ~ prev_nspp_native+scale +(1|site), 
              data = ., family = "binomial")%>%
  summary

prev_year_div%>%
  mutate(invaded = ifelse(invaded=="invaded",1,0), 
         prev_nspp_native = scale(prev_nspp_native)) %>%
  glm(invaded ~ prev_nspp_native+scale, 
              data = ., family = "binomial")%>%
  summary


# money plots ==================================================================
p2<-ggplot(all_scales %>% filter(invaded != 0) %>%
             mutate(invaded = ifelse(invaded=="invaded", 1,0)), 
           aes(x = nspp_native, y=invaded, color = scale)) +
  geom_smooth(method = "glm", method.args = list(family = "binomial")) +
  theme_classic()


p1<-ggplot(prev_year_div %>% filter(invaded != 0) %>%
             mutate(invaded = ifelse(invaded=="invaded", 1,0)), 
           aes(x = prev_nspp_native, y=invaded, color = scale)) +
  geom_smooth(method = "glm", method.args = list(family = "binomial")) +
  theme_classic()

ggarrange(p1,p2, common.legend = T, legend = "top")