import gleam/list
import utils/logger

pub fn logger_levels_test() {
  let levels = [
    logger.Log,
    logger.Info,
    logger.Warning,
    logger.Error,
  ]

  list.each(levels, fn(level) { logger.log("Test message", level) })
}
