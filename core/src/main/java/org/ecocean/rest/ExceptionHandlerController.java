package org.ecocean.rest;

import java.io.IOException;

import javax.servlet.http.HttpServletResponse;

import org.apache.commons.lang.exception.ExceptionUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.ResponseStatus;


@ControllerAdvice
public class ExceptionHandlerController {
    private Logger logger = LoggerFactory.getLogger(ExceptionHandlerController.class);

//    public static final String DEFAULT_ERROR_VIEW = "error";

//    @ExceptionHandler(value = {Exception.class, RuntimeException.class})
//    public ModelAndView defaultErrorHandler(HttpServletRequest request, Exception ex)
//    {
//        ModelAndView mav = new ModelAndView(DEFAULT_ERROR_VIEW);
//
//        ex.printStackTrace();
//
//        mav.addObject("datetime", new Date());
//        mav.addObject("exception", ex);
//        mav.addObject("url", request.getRequestURL());
//        return mav;
//    }

//    @ExceptionHandler({Exception.class, RuntimeException.class})
//    void handleBadRequests(HttpServletResponse response) throws IOException {
//        response.sendError(HttpStatus.BAD_REQUEST.value());
//    }

    @ExceptionHandler({Exception.class, RuntimeException.class})
    @ResponseStatus(value = HttpStatus.INTERNAL_SERVER_ERROR)
    @ResponseBody
    public ErrorInfo handleException5(final Exception ex, final HttpServletResponse response) throws IOException
    {
        logger.error("****Spring Handled Exception*****", ex);

        ErrorInfo info = new ErrorInfo();
        info.message = ex.getMessage();
        info.stack = ExceptionUtils.getFullStackTrace(ex);
        return info;
    }


    static class ErrorInfo
    {
        public String message;
        public String stack;
    }
}
