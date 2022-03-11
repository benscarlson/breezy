theme_eda <- theme_classic(base_family = 'Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    axis.text=element_text(size=10),
    axis.title=element_text(size=14),
    legend.text = element_text(size=10),
    legend.title = element_text(size=12),
    strip.text = element_text(size=9),
    strip.background = element_blank()
  )

theme_ms <- theme_classic(base_family='Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    axis.text=element_text(size=12),
    axis.title=element_text(size=14),
    legend.text = element_text(size=12),
    legend.title = element_text(size=14),
    strip.text = element_text(size=9),
    strip.background = element_blank()
  )

theme_map <- theme_classic(base_family='Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    legend.text = element_text(size=10),
    legend.title = element_text(size=12),
    axis.text = element_blank(),
    axis.title = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_blank()
  )

theme_map_dark <- theme(
  plot.background = element_rect(fill = "black", color='black'),
  plot.title = element_text(size=20,color='white'),
  plot.tag = element_text(size=18,color='white'),
  panel.background = element_rect(fill='black', colour='black'),
  panel.grid=element_blank(),
  axis.text=element_blank(),
  axis.title=element_blank(),
  axis.line=element_blank(),
  axis.ticks=element_blank(),
  legend.text=element_text(size=10,color='white'),
  legend.title=element_text(size=12,color='white'),
  legend.background=element_rect(fill='black',color='black'),
  strip.text=element_text(size=13,color='white'),
  strip.background=element_rect(fill='black',color='black')
)

theme_pres <- theme_classic(base_family='Helvetica') +
  theme(
    plot.title = element_text(size=20),
    plot.tag = element_text(size=18),
    axis.text=element_text(size=14),
    axis.title=element_text(size=18),
    legend.text = element_text(size=18),
    legend.title = element_text(size=18)
  )

theme_pres_dark <- theme(
  plot.background = element_rect(fill = "black", color='black'),
  plot.title = element_text(size=20,color='white'),
  plot.tag = element_text(size=18,color='white'),
  panel.background = element_rect(fill='black', colour='black'),
  panel.grid=element_blank(),
  axis.text=element_text(size=14,color="white"),
  axis.title=element_text(size=18,color='white'),
  axis.line=element_line(color='white'),
  axis.ticks=element_line(color='white'),
  legend.text=element_text(size=18,color='white'),
  legend.title=element_text(size=18,color='white'),
  legend.background=element_rect(fill='black',color='black'),
  strip.text=element_text(size=13,color='white'),
  strip.background=element_rect(fill='black',color='black')
)