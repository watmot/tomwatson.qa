import styled from 'styled-components';

export const Wrapper = styled.div`
  position: fixed;
  display: flex;
  align-items: center;
  bottom: 0;
  margin: 0.5rem;
  padding: 0.5rem;
  background: #f1f1f1;
  z-index: ${({ theme }) => theme.zIndex('version')};
`;

export const Text = styled.span`
  margin: 0 0.75rem;
`;

export const Button = styled.div`
  width: 1rem;
  height: 1rem;
  background: #dadada;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
`;
