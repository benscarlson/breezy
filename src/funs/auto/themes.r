theme_eda <- theme_classic(base_family = 'Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    axis.text=element_text(size=10),
    axis.title=element_text(size=14),
    legend.text = element_text(size=10),
    legend.title = element_text(size=12),
    strip.text = element_text(size=12)
  )

theme_ms <- theme_classic(base_family='Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    axis.text=element_text(size=12),
    axis.title=element_text(size=14),
    legend.text = element_text(size=12),
    legend.title = element_text(size=14)
  )

theme_map <- theme(
  plot.title = element_text(size=20),
  plot.tag = element_text(size=18),
  legend.text = element_text(size=10),
  legend.title = element_text(size=12),
  axis.text = element_blank(),
  axis.title = element_blank(),
  axis.ticks = element_blank(),
  axis.line = element_blank()
)